<#
.SYNOPSIS
    Ext JS 4 to 7 migration audit. Reports file-and-line hits per change category.

.DESCRIPTION
    A repeatable, dependency-free inventory of the mechanical change categories in an Ext JS 4
    codebase. Runs without Sencha registry access, so it also serves as the fallback when the
    Upgrade Adviser or its ESLint plugin is unavailable.

    Every category carries a mapping status. The status decides the work:

      Removed              gone, calls throw or silently do nothing, must fix
      CompatAlias          old name still translated by the framework, with a deprecation warning
      Deprecated           still present and working, schedule as debt
      ChangedDefault       same API, different behavior, usually server-visible, no error
      ChangedSignature     same name, different arguments or event payload
      Private              never public API, must re-derive against target source
      ReceiverDependent    only some receivers changed, verify each call site
      NoChange             matched by a broad pattern but valid on the target; subtract it
      Info                 context for another category, not work

    Statuses are stated for the Ext 7.x line and can differ between 7.0 and 7.9. The target for
    this migration is 7.7.0.31; confirm any status that drives a decision against that release's
    own API docs and source, and record when the check was made.

    Counts are candidates, not defects. They include commented-out code and string literals.
    MatchingLines counts lines that matched; Matches counts individual matches on those lines.
    Triage every category before planning any edit; see references/upgrade-map.md section 0.

    Boot-path output is candidates only. Which shell a user is served, what the browser actually
    fetches, which build profile is deployed, and whether a vendored locale file is still live are
    runtime facts this script cannot see: the choice of shell usually lives in the hosting
    application's controller, outside the scanned tree, and dynamic script injection leaves no
    static reference. Confirm every one of them per references/boot-path-evidence.md before
    planning against them. Where the browser and this script disagree, the browser is right.

    Counts are also tool-dependent. Codebases with mixed CRLF/LF line endings or non-ASCII content
    produce different line counts under different scanners, so a count from this script and a count
    from grep will not always agree. Use one tool consistently, diff its output against its own
    earlier baseline, and treat the trend as the signal rather than the absolute number.

.PARAMETER Path
    Application root to scan. Defaults to the current directory.

.PARAMETER SourceDir
    Application source folder, relative to Path. Defaults to "app".

.PARAMETER Json
    Write a machine-readable baseline to this file. Commit it and diff between phases.

.PARAMETER Detail
    Category name (or substring) to list individual file:line hits for.

.PARAMETER AppNamespace
    Application root namespace, used to find application code embedded in the vendored SDK and
    package trees. Inferred from app.json "name" when omitted.

.EXAMPLE
    .\extjs4-audit.ps1 -Path D:\Projects\WGR\WebContent -Json .\audit-phase0.json

.EXAMPLE
    .\extjs4-audit.ps1 -Detail writeAllFields
#>
[CmdletBinding()]
param(
    [string] $Path = '.',
    [string] $SourceDir = 'app',
    [string] $Json,
    [string] $Detail,
    [string] $AppNamespace
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $Path).Path
$src  = Join-Path $root $SourceDir
if (-not (Test-Path -LiteralPath $src)) {
    throw "Source folder not found: $src. Pass -SourceDir if the app source lives elsewhere."
}

# Framework, build output, and vendored third-party code are not application source.
#
# The root-level list is anchored to the scan root deliberately. An unanchored 'docs' segment also
# matches app/controller/docs, and an unanchored 'packages' segment also matches packages/local -
# where Cmd 6/7 keeps an application-owned theme package or a forked ux. Both are application code
# that a migration has to see, and excluding them makes the report read clean while hiding live
# source.
#
# Every directory actually skipped is recorded and printed with the scan boundaries. A silent
# exclusion is the one nobody checks.
$excludeRootDirs = @('build', 'ext', 'docs', '.sencha')
$excludeAnywhere = '(^|/)(node_modules|\.git)/|(^|/)sass/example/'
$skippedDirs     = @{}

function Test-Excluded {
    param([string] $FullName)

    $rel = $FullName
    if ($FullName.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
        $rel = $FullName.Substring($root.Length).TrimStart('\', '/')
    }
    $rel = $rel.Replace('\', '/')

    foreach ($d in $excludeRootDirs) {
        if ($rel -eq $d -or $rel.StartsWith(('{0}/' -f $d), [StringComparison]::OrdinalIgnoreCase)) {
            $script:skippedDirs[('{0}/' -f $d)] = 'scan-root level: framework, build output, or generated docs'
            return $true
        }
    }
    # Vendored packages, except packages/local - an application-owned package is application source.
    if ($rel -eq 'packages' -or $rel.StartsWith('packages/', [StringComparison]::OrdinalIgnoreCase)) {
        if (-not $rel.StartsWith('packages/local/', [StringComparison]::OrdinalIgnoreCase)) {
            $script:skippedDirs['packages/ (packages/local/ IS scanned)'] = 'vendored packages'
            return $true
        }
    }
    if ($rel -match $excludeAnywhere) {
        $script:skippedDirs['node_modules/, .git/, sass/example/'] = 'any level: not application source'
        return $true
    }
    return $false
}

Write-Host "Scanning $src" -ForegroundColor Cyan

$files = Get-ChildItem -LiteralPath $src -Recurse -File -Filter *.js |
    Where-Object { -not (Test-Excluded $_.FullName) }

# Application JavaScript living outside the conventional app/ tree: root-level bootstrap and
# support scripts, hand-placed overrides, and vendored integration code. Ext 4 projects
# accumulate these, and a scan limited to app/ reports a clean bill of health for them.
$extraDirs  = @('overrides', 'ecp', 'js', 'scripts')
$extraFiles = @('app.js', 'test.js')

foreach ($d in $extraDirs) {
    $dp = Join-Path $root $d
    if (Test-Path -LiteralPath $dp) {
        $files += Get-ChildItem -LiteralPath $dp -Recurse -File -Filter *.js |
            Where-Object { -not (Test-Excluded $_.FullName) }
    }
}
foreach ($extra in $extraFiles) {
    $p = Join-Path $root $extra
    if (Test-Path -LiteralPath $p) { $files += Get-Item -LiteralPath $p }
}
$files = $files | Sort-Object FullName -Unique

# Server-rendered pages carry inline JavaScript that the app/ scan never sees.
$pageFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Include *.jsp, *.jspf, *.tag, *.html -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-Excluded $_.FullName) -and (Select-String -LiteralPath $_.FullName -Pattern '<script' -Quiet -ErrorAction SilentlyContinue) }
if ($pageFiles) { $files += $pageFiles }

Write-Host ("{0} source files ({1} with inline page script)" -f $files.Count, $pageFiles.Count) -ForegroundColor Cyan

# Category, status, regex, and the note that tells a reader what to do about it.
$categories = @(
    @{ Name = 'reader root';               Status = 'Removed';           Pattern = '(^|[,{(\s])root\s*:\s*[''"]';                  Note = 'Ext.data.reader.Reader has no legacy root alias. rootProperty, or the reader silently returns no records. Excludes root:{} tree configs; still contains writer hits, see below.' }
    @{ Name = 'writer root';               Status = 'CompatAlias';       Multiline = $true; Pattern = 'writer\s*:\s*\{(?:[^{}]|\{[^{}]*\})*?root\s*:';  Note = 'Ext.data.writer.Json maps root to rootProperty and logs a deprecation warning. Works, identical wire format, and may stay as accepted debt once verified on the target release. Subtract from the reader-root count.' }
    @{ Name = 'tree root config';          Status = 'NoChange';          Pattern = '(^|[,{(\s])root\s*:\s*\{';                     Note = 'root:{} on a TreeStore or tree panel is still the supported config. Subtract from the reader-root count.' }
    @{ Name = 'writeAllFields';            Status = 'ChangedDefault';    Pattern = 'writeAllFields';                             Note = 'Default flipped true->false. Compare this count against the number of writers: the gap is your silent-data-loss exposure.' }
    @{ Name = 'extraParams direct access'; Status = 'Deprecated';        Pattern = '\.extraParams';                              Note = 'Use setExtraParams()/getExtraParams(). Direct mutation is the documented anti-pattern.' }
    @{ Name = 'reader .rawData';           Status = 'ChangedDefault';    Pattern = '(?<!load)\.rawData\b|\brawData\s*=\s*\w+\.get';  Note = 'Reader no longer retains raw data. Opt in via the target release keepRawData equivalent. Deliberately excludes loadRawData.' }
    @{ Name = 'store.loadRawData()';       Status = 'Info';              Pattern = 'loadRawData\s*\(';                            Note = 'Still supported. Listed only so it is not mistaken for a reader.rawData access.' }
    @{ Name = 'model .raw';                Status = 'Removed';           Pattern = '\.raw\b';                                    Note = 'Model raw property removed, and data is not a substitute - raw is pre-conversion, data is post-conversion. Resolve per call site: get() for one value, data for the converted object, keepRawData for the unconverted envelope. Never bulk-replace.' }
    @{ Name = 'record/store destroy()';    Status = 'ReceiverDependent'; Pattern = '\.destroyStore\(|\.destroy\(\)';             Note = 'On a record or store, destroy() now releases resources and erase() deletes server-side. On a component it is unchanged. Most hits are components.' }
    @{ Name = 'getRootNode()';             Status = 'ReceiverDependent'; Pattern = 'getRootNode\(';                              Note = 'Deprecated on TreeStore only. Ext.tree.Panel.getRootNode() is fine. Determine the receiver before touching anything.' }
    @{ Name = 'buffered store';            Status = 'Deprecated';        Pattern = 'buffered\s*:\s*true';                        Note = "buffered:true -> type:'buffered'." }
    @{ Name = 'groupers';                  Status = 'Removed';           Pattern = 'groupers\s*:';                               Note = 'Use grouper.' }
    @{ Name = 'associations';              Status = 'Deprecated';        Pattern = '(belongsTo|hasMany|associations)\s*:';       Note = 'Field-level reference config plus schema.' }
    @{ Name = 'validations';               Status = 'Deprecated';        Pattern = 'validations\s*:';                            Note = 'validators.' }
    @{ Name = 'useNull';                   Status = 'Removed';           Pattern = 'useNull';                                    Note = 'allowNull.' }
    @{ Name = 'Trigger field class';       Status = 'Deprecated';        Pattern = 'Ext\.form\.field\.Trigger';                  Note = 'Confirmed present in 7.7.0, deprecated since 5.0 and not used internally by the framework. Scheduled debt unless subclassed - see trigger internals.' }
    @{ Name = "xtype: 'trigger'";          Status = 'Deprecated';        Pattern = "xtype\s*:\s*['`"]trigger";                   Note = 'Works. Debt, not a blocker.' }
    @{ Name = 'trigger internals';         Status = 'Private';           Pattern = 'trigger[12]Cls|triggerCell|onTrigger[12]Click|triggerWrap'; Note = 'The real work. Re-derive against Ext.form.field.Text triggers.' }
    @{ Name = 'grid filters feature';      Status = 'Removed';           Pattern = "FiltersFeature|ftype\s*:\s*['`"]filters";    Note = 'Feature became the Ext.grid.filters.Filters plugin with per-column filter configs.' }
    @{ Name = 'verticalScroller';          Status = 'Removed';           Pattern = 'verticalScroller';                           Note = 'Ignored. Buffered rendering is on by default.' }
    @{ Name = 'autoScroll';                Status = 'ReceiverDependent'; Pattern = 'autoScroll';                                 Note = 'scrollable. Values are not one-to-one; verify per class on the target release.' }
    @{ Name = 'margins';                   Status = 'Removed';           Pattern = '(?<!default)margins\s*:';                    Note = 'margin, on the same component. Mechanical. The lookbehind keeps defaultMargins out: matching is case-insensitive, so a bare margins pattern also matches defaultMargins and conflates two different fixes.' }
    @{ Name = 'defaultMargins';            Status = 'Removed';           Pattern = 'defaultMargins\s*:';                         Note = 'NOT the same edit as margins. This is a box-layout config: the value moves to the owning container defaults.margin, so ownership changes. Verify each screen against its phase 0 screenshot rather than treating it as a rename.' }
    @{ Name = 'doLayout()';                Status = 'Removed';           Pattern = 'doLayout\(';                                 Note = 'updateLayout(), and check whether the call is needed at all.' }
    @{ Name = 'Abstract* base classes';    Status = 'Removed';           Pattern = 'Ext\.Abstract(Component|Container|Panel)|Ext\.dom\.AbstractElement'; Note = 'Merged into concrete base classes.' }
    @{ Name = 'removed Element methods';   Status = 'Removed';           Pattern = '\.(getHTML|replaceWith|setLeftTop|setBounds|isBorderBox|isTransparent|isDisplayed|getStyleSize|getComputedWidth|getComputedHeight|getAttributeNS)\('; Note = 'Removed from Ext.dom.Element. A hit on the boot path is a hard boot failure.' }
    @{ Name = 'Ext.EventManager';          Status = 'Deprecated';        Pattern = 'Ext\.EventManager';                          Note = 'Element Observable API.' }
    @{ Name = 'Ext.EventObject';           Status = 'Removed';           Pattern = 'Ext\.EventObject';                           Note = 'No longer a stable singleton.' }
    @{ Name = 'Ext.FocusManager';          Status = 'Removed';           Pattern = 'Ext\.FocusManager';                          Note = 'Removed; focus handling is built in.' }
    @{ Name = 'Ext.ux';                    Status = 'ChangedDefault';    Pattern = 'Ext\.ux';                                    Note = 'Separate ux package, must be declared in app.json requires. Verify each class still exists.' }
    @{ Name = 'framework override';        Status = 'Private';           Pattern = "Ext\.override\(|override\s*:\s*['`"]Ext\.";  Note = 'Must re-derive against target source. Read every one.' }
    @{ Name = 'autoCreateViewport';        Status = 'Deprecated';        Pattern = 'autoCreateViewport';                         Note = 'mainView on Ext.app.Application.' }
    @{ Name = 'explicit component id';     Status = 'ChangedDefault';    Pattern = "^\s*id\s*:\s*['`"]";                         Note = "Ext 5+ validates ids against /^[a-z_][a-z0-9\-_]*$/i. Dots and colons now throw." }
    @{ Name = 'constructed id';            Status = 'ChangedDefault';    Pattern = "id\s*:\s*[^'`",\r\n]*\+";                    Note = 'Ids built from data are the ones that violate the id pattern at runtime.' }
    @{ Name = 'Ext.chart';                 Status = 'ReceiverDependent'; Pattern = 'Ext\.chart';                                 Note = 'Ext.chart is ALSO the namespace of the supported charts package in 7.x, so a hit is only a defect for a legacy class. The Ext 4 package became ext-charts and was discontinued in Ext 6; the replacement charts package must be declared in app.json requires. Read each hit before calling it work.' }
    @{ Name = 'Ext.Direct';                Status = 'ChangedSignature';  Pattern = 'Ext\.[Dd]irect';                             Note = 'Verify remoting API shape against the target release.' }
    @{ Name = 'sync loading';              Status = 'ChangedDefault';    Pattern = 'Ext\.syncRequire|Ext\.Loader\.setConfig';     Note = 'Loader is asynchronous. Declare requires instead.' }
    @{ Name = 'hard-coded locale path';    Status = 'Removed';           Pattern = 'ext/locale|ext-lang-|locale/ext-lang';        Note = 'The locale package was renamed and relocated in Ext 6+. Any URL built by string concatenation against the vendored SDK breaks. Boot path.' }
    @{ Name = 'vendored SDK path';         Status = 'Removed';           Pattern = "['`"]ext/(src|packages|builds|resources)"; Note = 'A checked-in Ext 4 SDK referenced by literal path. Cmd 6/7 resolves the framework differently; every such path moves.' }
    @{ Name = 'server-injected DOM read';  Status = 'ChangedSignature';  Pattern = 'Ext\.get\s*\([''"][^''"]+[''"]\s*\)\s*\.'; Note = 'Reading a value the server wrote into the page. Check the method against the removed-Element-methods row; a hit there is a hard boot failure.' }
    @{ Name = 'Ext.ModelManager';          Status = 'Removed';           Pattern = 'Ext\.ModelManager';                          Note = 'The Ext 4 root singleton is gone - Sencha uses it as the worked example for their removed-class lint rule. Resolve models through the schema or Ext.ClassManager. Ext.data.ModelManager is the separate, merely deprecated form; check which one each hit is.' }
    @{ Name = 'addEvents()';               Status = 'Removed';           Pattern = 'addEvents\s*\(';                             Note = 'Event pre-registration was removed; Ext 7 events need no declaration. Delete the call and keep the event names and fireEvent sites exactly as they are.' }
    @{ Name = 'Ext.escapeRe()';            Status = 'Removed';           Pattern = 'Ext\.escapeRe\s*\(';                         Note = 'Ext.String.escapeRegex().' }
    @{ Name = 'model idgen';               Status = 'Removed';           Pattern = 'idgen\s*:|Ext\.data\.SequentialIdGenerator';  Note = 'idgen -> identifier, Ext.data.SequentialIdGenerator -> Ext.data.identifier.Sequential. Read the phantom-id section of grid-and-data.md first: the identifier decides the id the server receives on create, so this is a server-contract change, not a rename.' }
    @{ Name = 'compat alternate names';    Status = 'CompatAlias';       Pattern = 'Ext\.data\.Errors|Ext\.form\.NumberField|Ext\.grid\.RowNumberer|Ext\.grid\.column\.CheckColumn|Ext\.AbstractPlugin'; Note = 'Alternate class names the Ext 7 line still resolves. Keep them - renaming is churn, not migration. Verify each against the target release, and read any subclass that reaches into the old internals, which is where the real work is.' }
    @{ Name = 'generated-markup access';   Status = 'Private';           Pattern = 'dataset\.recordindex|elementFromPoint|getAttribute\s*\(\s*[''"]data-recordindex'; Note = 'Application code reading framework-generated data attributes or hit-testing the grid DOM. Ext 5+ buffered rendering renders only visible rows and changed that markup, so these fail silently rather than throwing. Re-derive against the target release.' }
)

$results = @()
$detailHits = @()

# Commented-out code and string literals are candidates, not work. The script cannot parse
# JavaScript, so this is a deliberate approximation: a hit is treated as commented when its line
# starts a line or block comment, or when a // appears before the match on the same line. A match
# inside a multi-line /* ... */ that began on an earlier line is NOT detected. ActiveLines is
# therefore an upper bound on real work and a lower bound on noise - read the hits either way.
function Test-HitCommented {
    param($Hit)

    $line = [string] $Hit.Line
    if ($line.TrimStart() -match '^(//|/\*|\*(?!/))') { return $true }

    $c = $line.IndexOf('//')
    if ($c -lt 0) { return $false }
    if ($Hit.Matches -and $Hit.Matches.Count) {
        $v = [string] $Hit.Matches[0].Value
        if ($v) {
            $p = $line.IndexOf($v, [StringComparison]::OrdinalIgnoreCase)
            if ($p -ge 0) { return ($c -lt $p) }
        }
    }
    return $false
}

foreach ($cat in $categories) {
    if ($cat.Multiline) {
        # Config blocks span lines, so match whole-file content instead of individual lines.
        # One hit object per match, carrying a real line number and the real matched text: these
        # categories feed the subtraction the reader-root note asks for, so MatchingLines has to
        # mean lines and -Detail has to print code, exactly as it does for single-line categories.
        $hits = @()
        foreach ($sf in $files) {
            $c = Get-Content -LiteralPath $sf.FullName -Raw -ErrorAction SilentlyContinue
            if ($null -eq $c) { continue }
            foreach ($m in [regex]::Matches($c, $cat.Pattern, 'Singleline')) {
                # Newlines before the match. Correct for LF and CRLF alike.
                $lineNo = ([regex]::Matches($c.Substring(0, $m.Index), "`n")).Count + 1
                $hits += [pscustomobject]@{
                    Path       = $sf.FullName
                    LineNumber = $lineNo
                    Line       = ($m.Value -split "`r?`n")[0]
                    Matches    = @($m)
                }
            }
        }
    }
    else {
        $hits = $files | Select-String -Pattern $cat.Pattern -AllMatches -ErrorAction SilentlyContinue
    }
    $fileCount = ($hits | Select-Object -ExpandProperty Path -Unique).Count
    $matchCount = [int](($hits | ForEach-Object { $_.Matches.Count } | Measure-Object -Sum).Sum)
    if (-not $matchCount) { $matchCount = 0 }
    # Distinct lines, not hit objects: a multiline category can emit several matches on one line.
    $lineCount = ($hits | ForEach-Object { '{0}:{1}' -f $_.Path, $_.LineNumber } | Sort-Object -Unique).Count
    $activeCount = ($hits | Where-Object { -not (Test-HitCommented $_) } |
        ForEach-Object { '{0}:{1}' -f $_.Path, $_.LineNumber } | Sort-Object -Unique).Count

    $results += [pscustomobject]@{
        Category      = $cat.Name
        Status        = $cat.Status
        MatchingLines = $lineCount
        ActiveLines   = $activeCount
        Matches       = $matchCount
        Files         = $fileCount
        Note          = $cat.Note
    }

    if ($Detail -and $cat.Name -like "*$Detail*") {
        $detailHits += $hits | ForEach-Object {
            [pscustomobject]@{
                Category  = $cat.Name
                Location  = ('{0}:{1}' -f $_.Path.Replace($root, '').TrimStart('\', '/'), $_.LineNumber)
                Commented = (Test-HitCommented $_)
                Line      = $_.Line.Trim()
            }
        }
    }
}

# Page shells: server-rendered pages that actually boot the application.
# Case-SENSITIVE matching is required. A case-insensitive 'Ext\.' matches the tail of
# ${pageContext.request...} and reports every ordinary JSP in the project as an Ext shell.
#
# Three independent facts, deliberately not collapsed into one enum:
#
#   CmdManaged     - who maintains the page: Sencha Cmd rewrites it, or a human does.
#   LoadsCandidate - what the page appears to put on the client. A CANDIDATE only; the browser
#                    is the authority. See references/boot-path-evidence.md.
#   Liveness       - which shell the deployment actually serves. Not decidable from the web
#                    content tree at all: the choice normally lives in the hosting application's
#                    controller. Always reported undetermined here.
#
# Cmd's x-compile and x-bootstrap directives say who manages the page, NOT what it loads. They
# are live directives written as HTML comments, so reading them as a microloader signal
# misreports every Cmd-managed page that references a prebuilt bundle - which is the normal
# arrangement when the deployed page is the build output.
$cmdPageName = $null
$senchaCfgPath = Join-Path $root '.sencha/app/sencha.cfg'
if (Test-Path -LiteralPath $senchaCfgPath) {
    $cfgText = Get-Content -LiteralPath $senchaCfgPath -Raw -ErrorAction SilentlyContinue
    if ($cfgText -match '(?m)^\s*app\.page\.name\s*=\s*(.+?)\s*$') { $cmdPageName = $Matches[1] }
}

$shellHits = @()
$shellFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Include *.jsp, *.html -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-Excluded $_.FullName) }
foreach ($f in $shellFiles) {
    $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # A commented-out script tag loads nothing, so strip HTML comments before asking what the
    # page loads. Cmd's directives are read from the unstripped text, because they ARE comments.
    $live = [regex]::Replace($content, '(?s)<!--.*?-->', '')
    $srcs = @([regex]::Matches($live, '(?is)<script\b[^>]*\bsrc\s*=\s*["'']([^"'']+)["'']') |
        ForEach-Object { $_.Groups[1].Value })

    $hasApplication   = $live -cmatch 'Ext\.application\s*\(|Ext\.onReady\s*\('
    $hasCompile       = $content -cmatch 'x-compile'
    $hasBootstrapMark = $content -cmatch 'x-bootstrap'
    $isCmdPage        = [bool]($cmdPageName -and $f.Name -eq $cmdPageName)

    if (-not ($hasApplication -or $srcs.Count -or $hasCompile -or $hasBootstrapMark)) { continue }

    # What the browser would be asked to fetch, decided by actual script src values only.
    $microloader  = [bool](@($srcs | Where-Object { $_ -match '(?i)(^|/)bootstrap\.js(\?|$)|microloader' }).Count)
    $bundleSrc    = @($srcs | Where-Object { $_ -match '(?i)build/(testing|production|development)/' })[0]
    $frameworkSrc = @($srcs | Where-Object { $_ -match '(?i)(^|/)(ext-all(-debug|-dev)?|ext-dev|ext)\.js(\?|$)' })[0]

    $loads = if ($microloader)        { 'microloader' }
             elseif ($bundleSrc)      { 'prebuilt-bundle' }
             elseif ($frameworkSrc)   { 'source-framework' }
             elseif ($hasApplication) { 'inline-boot, no framework src' }
             else                     { 'none detected' }

    $profile = if ($bundleSrc -and $bundleSrc -match '(?i)build/(testing|production|development)/') { $Matches[1] } else { '(none)' }
    $doctype = if ($content -match '(?im)^\s*<!DOCTYPE[^>]*>') { $Matches[0].Trim() } else { '(none)' }

    $shellHits += [pscustomobject]@{
        Shell            = $f.FullName.Replace($root, '').TrimStart('\', '/')
        CmdManaged       = [bool]($hasCompile -or $hasBootstrapMark -or $isCmdPage)
        LoadsCandidate   = $loads
        ProfileCandidate = $profile
        DoctypeSource    = if ($doctype -match 'XHTML') { 'XHTML' } elseif ($doctype -match 'HTML 4') { 'HTML4' } elseif ($doctype -match '(?i)^<!DOCTYPE html>$') { 'HTML5' } else { $doctype }
        Liveness         = 'undetermined'
        ScriptSrcs       = ($srcs -join ' ')
    }
}

# Stylesheets that reach into framework markup. Ext 5/6/7 changed the classic DOM structure,
# so a selector written against Ext 4's markup can silently stop matching with no build error.
$cssHits = @()
$cssFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Include *.css, *.scss -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-Excluded $_.FullName) }
foreach ($f in $cssFiles) {
    $lines = Select-String -LiteralPath $f.FullName -Pattern '\.x-[a-z0-9\-]+' -AllMatches -ErrorAction SilentlyContinue
    if ($lines) {
        $cssHits += [pscustomobject]@{
            File          = $f.FullName.Replace($root, '').TrimStart('\', '/')
            MatchingLines = $lines.Count
            Selectors     = ($lines | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Sort-Object -Unique).Count
        }
    }
}

# Build customization: anything that wraps, post-processes, or bypasses `sencha app build`.
$buildHits = @()
$buildCandidates = Get-ChildItem -LiteralPath $root -File -Include *.bat, *.cmd, *.sh, *.xml, *.gradle -ErrorAction SilentlyContinue
$buildCandidates += Get-ChildItem -LiteralPath $root -Recurse -File -Include build.xml, pom.xml, *.build.xml -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-Excluded $_.FullName) }
foreach ($f in ($buildCandidates | Sort-Object FullName -Unique)) {
    $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    if ($content -match '(?i)sencha|app build|\bcompile\b.*classpath') {
        $buildHits += [pscustomobject]@{
            File        = $f.FullName.Replace($root, '').TrimStart('\', '/')
            RawCompile  = [bool]($content -match '(?i)sencha.*\bcompile\b|\bunion\b.*\bconcatenate\b')
            CopiesCss   = [bool]($content -match '(?i)(copy|cp)\s.*\.css|AppendAllText')
            PinsCmdPath = [bool]($content -match '(?i)sencha\.jar|Sencha[\/]Cmd[\/][0-9]')
            Liveness    = 'undetermined'
        }
    }
}

# ---------------------------------------------------------------------------------------------
# Application code embedded in a vendored dependency.
#
# The scan above deliberately excludes the framework and package trees, so anything the
# application owns *inside* them is invisible to it. An Ext 4 project that hand-appended
# application overrides to a vendored locale file therefore reports a much cleaner inventory
# than it actually has, and that code is destroyed the moment the vendored SDK is deleted.
#
# build/ is not scanned here: it is generated from the application source, so application code
# in it is expected. That tree is the build contract's business, not this pass's.
if (-not $AppNamespace) {
    $appJsonPath = Join-Path $root 'app.json'
    if (Test-Path -LiteralPath $appJsonPath) {
        $ajText = Get-Content -LiteralPath $appJsonPath -Raw -ErrorAction SilentlyContinue
        if ($ajText -match '"name"\s*:\s*"([^"]+)"') { $AppNamespace = $Matches[1] }
    }
}

$vendorDirs = @('ext', 'packages') |
    ForEach-Object { Join-Path $root $_ } |
    Where-Object { Test-Path -LiteralPath $_ }

# Classpath and build declarations, so an embedded file can be reported as built or not built.
$classpathText = ''
$classpathSources = @()
foreach ($cf in @('.sencha/app/sencha.cfg', '.sencha/workspace/sencha.cfg', 'app.json', 'bootstrap.json')) {
    $cfp = Join-Path $root $cf
    if (Test-Path -LiteralPath $cfp) {
        $t = Get-Content -LiteralPath $cfp -Raw -ErrorAction SilentlyContinue
        $classpathText += $t
        $classpathSources += [pscustomobject]@{ File = $cf; Text = $t }
    }
}
foreach ($bf in ($buildCandidates | Sort-Object FullName -Unique)) {
    $t = Get-Content -LiteralPath $bf.FullName -Raw -ErrorAction SilentlyContinue
    $classpathText += $t
    $classpathSources += [pscustomobject]@{ File = $bf.FullName.Replace($root, '').TrimStart('\', '/'); Text = $t }
}

# Literal vendored-tree paths referenced from application source, keyed by directory so a URL
# assembled by concatenation - "ext/locale/ext-lang-{0}.js" - still resolves to its folder.
$vendorRefs = @{}
foreach ($h in ($files | Select-String -Pattern '["''](?:\.{0,2}/)?((?:ext|packages)/[A-Za-z0-9_\-./]*)' -AllMatches -ErrorAction SilentlyContinue)) {
    foreach ($m in $h.Matches) {
        $d = $m.Groups[1].Value -replace '/[^/]*$', ''
        if ($d -and -not $vendorRefs.ContainsKey($d)) {
            $vendorRefs[$d] = ('{0}:{1}' -f $h.Path.Replace($root, '').TrimStart('\', '/'), $h.LineNumber)
        }
    }
}

$embedded  = @()
$localeInv = @()
foreach ($vd in $vendorDirs) {
    foreach ($vf in (Get-ChildItem -LiteralPath $vd -Recurse -File -Filter *.js -ErrorAction SilentlyContinue)) {
        $vc = Get-Content -LiteralPath $vf.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $vc) { continue }

        $appClasses = 0
        $appOverrides = 0
        if ($AppNamespace) {
            $ns = [regex]::Escape($AppNamespace)
            $appClasses   = [regex]::Matches($vc, ('Ext\.define\s*\(\s*[''"]' + $ns + '\.')).Count
            $appOverrides = [regex]::Matches($vc, ('override\s*:\s*[''"]' + $ns + '\.')).Count
        }
        $extOverrides = [regex]::Matches($vc, 'override\s*:\s*[''"]Ext\.').Count

        $rel     = $vf.FullName.Replace($root, '').TrimStart('\', '/')
        $relDir  = ($rel.Replace('\', '/') -replace '/[^/]+$', '')
        $onCp    = [bool]($classpathText -match [regex]::Escape($relDir))
        $refSite = if ($vendorRefs.ContainsKey($relDir)) { $vendorRefs[$relDir] } else { '' }

        if ($appClasses -or $appOverrides) {
            $embedded += [pscustomobject]@{
                File               = $rel
                AppClasses         = $appClasses
                AppOverrides       = $appOverrides
                FrameworkOverrides = $extOverrides
                OnBuildClasspath   = $onCp
                ReferencedFrom     = $refSite
            }
        }

        # Localization inventory. A locale file earns a row whether or not it carries application
        # overrides: a dead translation has to be proven dead before anyone drops it.
        if ($vf.Name -match '^(ext-lang|ext-locale)[-_.]') {
            $shellRef = @($shellHits | Where-Object { $_.ScriptSrcs -match [regex]::Escape($vf.Name) })
            $mech = if ($onCp)               { 'build classpath' }
                    elseif ($shellRef.Count) { 'script tag' }
                    elseif ($refSite)        { 'dynamic injection' }
                    else                     { 'unreferenced' }
            $localeInv += [pscustomobject]@{
                Locale             = ($vf.BaseName -replace '^(ext-lang|ext-locale)[-_]', '')
                File               = $rel
                LoadMechanism      = $mech
                InjectedFrom       = $refSite
                AppOverrides       = $appOverrides
                FrameworkOverrides = $extOverrides
                Active             = 'unconfirmed'
            }
        }
    }
}

# ---------------------------------------------------------------------------------------------
# Vendored subtrees named on the build classpath.
#
# The embedded-application-code pass above finds application code by NAMESPACE. It cannot see code
# the application depends on that carries somebody else's namespace - most commonly stock Ext.ux
# classes relocated out of ext/examples/ux into ext/src/ux so that an "ext/src" classpath entry
# resolves them. That relocation is invisible to a namespace search, invisible to the source scan
# because it lives under the vendored tree, and deleted along with the SDK. Any vendored directory
# the build classpath names is therefore a dependency to account for before the framework moves.
$vendorCp = @()
foreach ($cs in $classpathSources) {
    foreach ($m in [regex]::Matches($cs.Text, '(?i)(?<![A-Za-z0-9_\-./])((?:ext|packages)/[A-Za-z0-9_\-./]+)')) {
        $d = $m.Groups[1].Value.TrimEnd('/')
        $abs = Join-Path $root ($d -replace '/', '\')
        if (-not (Test-Path -LiteralPath $abs -PathType Container)) { continue }
        if ($vendorCp | Where-Object { $_.Directory -eq $d -and $_.NamedIn -eq $cs.File }) { continue }
        $vendorCp += [pscustomobject]@{
            Directory = $d
            NamedIn   = $cs.File
            JsFiles   = @(Get-ChildItem -LiteralPath $abs -Recurse -File -Filter *.js -ErrorAction SilentlyContinue).Count
        }
    }
}

# Sencha Cmd merges its generated code into app.js. A leftover merge marker is direct evidence
# that the merge already failed here once, which belongs in the upgrade-in-place versus
# transplant decision (SKILL.md, phase 1) rather than being discovered during it.
$mergeMarkers = @()
foreach ($mh in ($files | Select-String -Pattern '^(<{7}|>{7})' -ErrorAction SilentlyContinue)) {
    $mergeMarkers += [pscustomobject]@{
        Location = ('{0}:{1}' -f $mh.Path.Replace($root, '').TrimStart('\', '/'), $mh.LineNumber)
        Line     = $mh.Line.Trim()
    }
}

Write-Host ''
$results | Sort-Object @{Expression = 'Status'; Descending = $false }, @{Expression = 'MatchingLines'; Descending = $true } |
    Format-Table Category, Status, MatchingLines, ActiveLines, Matches, Files -AutoSize
Write-Host 'MatchingLines counts every line that matched. ActiveLines subtracts lines that are commented' -ForegroundColor DarkGray
Write-Host 'out (approximated - see Test-HitCommented). Neither is a defect count.' -ForegroundColor DarkGray

if ($shellHits) {
    Write-Host 'Candidate page shells:' -ForegroundColor Yellow
    $shellHits | Format-Table Shell, CmdManaged, LoadsCandidate, ProfileCandidate, DoctypeSource, Liveness -AutoSize
    Write-Host 'Every shell needs a page-shell contract entry. See references/tooling-and-build.md section 8.' -ForegroundColor Yellow
    Write-Host 'CmdManaged says who maintains the page. It does NOT say what the page loads: Cmd x-compile and' -ForegroundColor Yellow
    Write-Host 'x-bootstrap directives are live HTML comments, and a Cmd-managed page commonly references a' -ForegroundColor Yellow
    Write-Host 'prebuilt bundle. LoadsCandidate and ProfileCandidate come from script src values only, and' -ForegroundColor Yellow
    Write-Host 'Liveness is not decidable from this tree at all. Confirm all three in a browser against the' -ForegroundColor Yellow
    Write-Host 'running application: references/boot-path-evidence.md.' -ForegroundColor Yellow
    Write-Host ''
}

if ($embedded) {
    Write-Host ("Application code embedded in vendored dependency (namespace '{0}'):" -f $AppNamespace) -ForegroundColor Red
    $embedded | Sort-Object AppOverrides -Descending | Format-Table -AutoSize
    Write-Host 'Excluded from the source scan above, and destroyed when the vendored SDK is removed.' -ForegroundColor Red
    Write-Host 'Classify every file here, and extract the active part, before deleting anything under it.' -ForegroundColor Red
    Write-Host ''
}

if ($vendorCp) {
    Write-Host 'Vendored directories named on the build classpath:' -ForegroundColor Yellow
    $vendorCp | Sort-Object Directory | Format-Table Directory, JsFiles, NamedIn -AutoSize
    Write-Host 'The pass above finds application code by namespace. This one catches what it cannot see:' -ForegroundColor Yellow
    Write-Host 'third-party code the build resolves from inside the vendored tree - stock ux classes moved' -ForegroundColor Yellow
    Write-Host 'into ext/src/ux being the usual case. Replacing the framework deletes it. Account for every' -ForegroundColor Yellow
    Write-Host 'row before the SDK moves, and re-declare what is still needed as a package in app.json.' -ForegroundColor Yellow
    Write-Host ''
}
elseif (-not $AppNamespace) {
    Write-Host 'App namespace not determined (no "name" in app.json), so the embedded-application-code pass' -ForegroundColor Yellow
    Write-Host 'was skipped. Re-run with -AppNamespace to cover the vendored SDK and package trees.' -ForegroundColor Yellow
    Write-Host ''
}

if ($localeInv) {
    # Only locale files the application has a stake in earn a row. The framework ships dozens of
    # its own, in source and built copies, and the target release replaces all of them wholesale:
    # they are a count, not an inventory. The JSON baseline keeps the full list either way.
    $appLoc = @($localeInv | Where-Object { $_.AppOverrides -gt 0 -or $_.LoadMechanism -ne 'unreferenced' })
    $fwLoc  = @($localeInv | Where-Object { $_.AppOverrides -eq 0 -and $_.LoadMechanism -eq 'unreferenced' })

    Write-Host 'Localization inventory:' -ForegroundColor Yellow
    if ($appLoc.Count) {
        $appLoc | Sort-Object Locale | Format-Table Locale, File, LoadMechanism, AppOverrides, FrameworkOverrides, Active, InjectedFrom -AutoSize
    }
    if ($fwLoc.Count) {
        Write-Host ('  plus {0} framework-only locale file(s) covering {1} locale(s), none referenced from' -f $fwLoc.Count, (($fwLoc | Select-Object -ExpandProperty Locale -Unique).Count)) -ForegroundColor DarkGray
        Write-Host '  application source. The target release replaces those wholesale; the rows above are the' -ForegroundColor DarkGray
        Write-Host '  ones that carry work.' -ForegroundColor DarkGray
        Write-Host ''
    }

    $liveLoc = @($localeInv | Where-Object { $_.AppOverrides -gt 0 -and $_.LoadMechanism -ne 'unreferenced' })
    if ($liveLoc.Count) {
        $liveOvr = [int](($liveLoc | ForEach-Object { $_.AppOverrides } | Measure-Object -Sum).Sum)
        Write-Host ('BLOCKER: {0} locale file(s) in the vendored SDK carry {1} application translation override(s)' -f $liveLoc.Count, $liveOvr) -ForegroundColor Red
        Write-Host 'and are still reachable. Extract them before removing the SDK: the locale package moved in' -ForegroundColor Red
        Write-Host 'Ext 6+, so the framework half is replaced and the application half has nowhere to go unless' -ForegroundColor Red
        Write-Host 'it is rehomed first.' -ForegroundColor Red
    }
    Write-Host 'Active stays unconfirmed until a browser capture shows which locale files are actually' -ForegroundColor Yellow
    Write-Host 'requested, and in which order: references/boot-path-evidence.md.' -ForegroundColor Yellow
    Write-Host ''
}

if ($mergeMarkers) {
    Write-Host 'Unresolved code-generation merge markers:' -ForegroundColor Red
    $mergeMarkers | Format-Table -AutoSize
    Write-Host 'Cmd code generation already failed to merge here. Evidence for the upgrade-in-place versus' -ForegroundColor Red
    Write-Host 'clean-scaffold-and-transplant decision; see SKILL.md, phase 1.' -ForegroundColor Red
    Write-Host ''
}

if ($cssHits) {
    Write-Host 'Stylesheets coupled to framework markup:' -ForegroundColor Yellow
    $cssHits | Sort-Object MatchingLines -Descending | Format-Table -AutoSize
    Write-Host 'Each distinct .x- selector must be re-verified against the target release DOM.' -ForegroundColor Yellow
    Write-Host ''
}

if ($buildHits) {
    Write-Host 'Candidate build customization outside Sencha Cmd:' -ForegroundColor Yellow
    $buildHits | Format-Table -AutoSize
    Write-Host 'A wrapper that raw-compiles, concatenates, or hand-assembles CSS is a build contract IF it is' -ForegroundColor Yellow
    Write-Host 'still the build. The flags describe what the file does, not whether anyone runs it: a retired' -ForegroundColor Yellow
    Write-Host 'wrapper left in the tree sets exactly the same flags as a live one, so Liveness is undetermined' -ForegroundColor Yellow
    Write-Host 'here for the same reason it is for page shells. Establish it from the project documentation, the' -ForegroundColor Yellow
    Write-Host 'CI configuration, or by asking - then reproduce each live step deliberately on the target, and' -ForegroundColor Yellow
    Write-Host 'retire each dead one deliberately. Do not assume `sencha app build` alone replaces a live one.' -ForegroundColor Yellow
}

$blockers = $results | Where-Object { $_.Status -eq 'Removed' -and $_.MatchingLines -gt 0 }
$silent   = $results | Where-Object { $_.Status -eq 'ChangedDefault' -and $_.MatchingLines -gt 0 }

Write-Host ''
$blockerActive = [int](($blockers | ForEach-Object { $_.ActiveLines } | Measure-Object -Sum).Sum)

Write-Host ("Removed-API categories with hits (fix required): {0} ({1} active lines)" -f $blockers.Count, $blockerActive) -ForegroundColor Red
Write-Host ("Changed-default categories with hits (silent behavior change): {0}" -f $silent.Count) -ForegroundColor Magenta
Write-Host 'Counts are candidates, not defects. Triage by status before planning any edit.' -ForegroundColor DarkGray

Write-Host ''
Write-Host 'Scan boundaries - what this report does not cover:' -ForegroundColor Yellow
Write-Host ("  Scanned root     : {0}" -f $root) -ForegroundColor DarkGray
Write-Host ("  Source folder    : {0}" -f $src) -ForegroundColor DarkGray
Write-Host ("  Excluded at root : {0}" -f (($excludeRootDirs | ForEach-Object { '{0}/' -f $_ }) -join ', ')) -ForegroundColor DarkGray
Write-Host  '  Excluded anywhere: node_modules/, .git/, sass/example/' -ForegroundColor DarkGray
if ($skippedDirs.Count) {
    Write-Host '  Actually skipped :' -ForegroundColor DarkGray
    foreach ($k in ($skippedDirs.Keys | Sort-Object)) {
        Write-Host ('    {0,-42} {1}' -f $k, $skippedDirs[$k]) -ForegroundColor DarkGray
    }
}
Write-Host '  Not covered: the hosting application - the Java/JSP controllers and configuration that' -ForegroundColor DarkGray
Write-Host '  decide which shell and which locale a user is served; the build output tree; the vendored' -ForegroundColor DarkGray
Write-Host '  SDK beyond the embedded-application-code pass; and everything only observable at runtime.' -ForegroundColor DarkGray
Write-Host '  Shell Liveness, LoadsCandidate, ProfileCandidate and locale Active are candidates until' -ForegroundColor DarkGray
Write-Host '  confirmed per references/boot-path-evidence.md.' -ForegroundColor DarkGray

if ($Detail) {
    Write-Host ''
    Write-Host ("Detail for '{0}':" -f $Detail) -ForegroundColor Cyan
    $detailHits | Format-Table Location, Commented, Line -AutoSize -Wrap
}

if ($Json) {
    [pscustomobject]@{
        GeneratedUtc = (Get-Date).ToUniversalTime().ToString('o')
        Root         = $root
        SourceFiles  = $files.Count
        AppNamespace    = $AppNamespace
        Categories      = $results
        PageShells      = $shellHits
        EmbeddedAppCode = $embedded
        VendorClasspath = $vendorCp
        LocaleInventory = $localeInv
        MergeMarkers    = $mergeMarkers
        BuildScripts    = $buildHits
        Stylesheets     = $cssHits
        Boundaries      = [pscustomobject]@{
            SourceFolder     = $src
            ExcludedRootDirs = $excludeRootDirs
            ExcludedAnywhere = $excludeAnywhere
            SkippedDirs      = $skippedDirs
            NotCovered      = @(
                'hosting application (Java/JSP controllers and configuration)',
                'build output tree',
                'vendored SDK beyond the embedded-application-code pass',
                'runtime behavior'
            )
            CandidateFields = @('PageShells.Liveness', 'PageShells.LoadsCandidate', 'PageShells.ProfileCandidate', 'LocaleInventory.Active', 'BuildScripts.Liveness')
            ConfirmWith     = 'references/boot-path-evidence.md'
        }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Json -Encoding UTF8
    Write-Host ''
    Write-Host "Baseline written to $Json. Commit it and diff at every phase boundary." -ForegroundColor Green
}
