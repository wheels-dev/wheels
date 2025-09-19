[Setup]
AppName=Wheels Installer
AppVersion=1.0
DefaultDirName={tmp}
DisableDirPage=yes
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=wheels-installer
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
Uninstallable=no

[Files]
Source: "install-wheels.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall ignoreversion

[Run]
Filename: "powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{tmp}\install-wheels.ps1"" -InstallPath ""{code:GetInstallPath}"" {code:GetForceParam} {code:GetSkipPathParam} -AppName ""{code:GetAppName}"" -Template ""{code:GetTemplate}"" -ReloadPassword ""{code:GetReloadPassword}"" -DatasourceName ""{code:GetDatasource}"" -CFMLEngine ""{code:GetEngine}"" {code:GetUseH2Param} {code:GetBootstrapParam} {code:GetInitPkgParam} -ApplicationBasePath ""{code:GetAppBasePath}"""; \
  StatusMsg: "Running Wheels installer script..."; \
  Flags: waituntilterminated

[Code]
var
  InstallDirPage, AppBaseDirPage: TInputDirWizardPage;
  TemplatesPage, EnginePage, OptionsPage, SummaryPage: TWizardPage;
  CmdOptionsPage: TWizardPage;
  ForceCheck, SkipPathCheck, H2Check, BootstrapCheck, InitPkgCheck: TCheckBox;
  SummaryMemo: TMemo;
  lbl, ForceInfoLabel: TLabel;

  // TEdit controls for application inputs
  AppQueryPage: TWizardPage;
  AppNameEdit, ReloadPwdEdit, DSNEdit: TEdit;

  // Radio buttons
  TemplateRadio1, TemplateRadio2, TemplateRadio3, TemplateRadio4, TemplateRadio5: TRadioButton;
  EngineRadio1, EngineRadio2, EngineRadio3, EngineRadio4, EngineRadio5, EngineRadio6, EngineRadio7: TRadioButton;

procedure InitializeWizard();
var
  topPos: Integer;
begin
  { === Page 1: CommandBox directory === }
  InstallDirPage := CreateInputDirPage(
    wpWelcome,
    'CommandBox Installation Path',
    'Choose where CommandBox will be installed.',
    'CommandBox is the CLI runtime used to scaffold and manage Wheels applications.',
    False, ''
  );
  InstallDirPage.Add('');
  InstallDirPage.Values[0] := ExpandConstant('{pf}\CommandBox');

  { === Page 1b: CommandBox options === }
  CmdOptionsPage := CreateCustomPage(InstallDirPage.ID,
    'CommandBox Options',
    'Optional settings for CommandBox installation.');

  ForceCheck := TCheckBox.Create(WizardForm);
  ForceCheck.Parent := CmdOptionsPage.Surface;
  ForceCheck.Left := 0;
  ForceCheck.Top := 8;
  ForceCheck.Width := CmdOptionsPage.SurfaceWidth;
  ForceCheck.Caption := 'Force reinstall CommandBox if already installed';
  ForceCheck.Checked := False;

  // Optional info label under first checkbox
  ForceInfoLabel := TLabel.Create(WizardForm);
  ForceInfoLabel.Parent := CmdOptionsPage.Surface;
  ForceInfoLabel.Left := 16;  // indent slightly
  ForceInfoLabel.Top := ForceCheck.Top + ForceCheck.Height + 2;
  ForceInfoLabel.Width := CmdOptionsPage.SurfaceWidth - 16;
  ForceInfoLabel.Caption := '(this will overwrite existing installation).';

  SkipPathCheck := TCheckBox.Create(WizardForm);
  SkipPathCheck.Parent := CmdOptionsPage.Surface;
  SkipPathCheck.Left := 0;
  SkipPathCheck.Top := ForceInfoLabel.Top + ForceInfoLabel.Height + 8; // add extra space
  SkipPathCheck.Width := CmdOptionsPage.SurfaceWidth;
  SkipPathCheck.Caption := 'Skip adding CommandBox to system PATH';
  SkipPathCheck.Checked := True;

  { === Page 2: App configuration using TEdit with labels === }
  topPos := 8;
  AppQueryPage := CreateCustomPage(CmdOptionsPage.ID,
    'Application Configuration',
    'Enter your application details below.');

  // Application name
  lbl := TLabel.Create(WizardForm);
  lbl.Parent := AppQueryPage.Surface; lbl.Top := topPos; lbl.Left := 0; lbl.Width := AppQueryPage.SurfaceWidth;
  lbl.Caption := 'Application Name:'; topPos := topPos + 16;
  AppNameEdit := TEdit.Create(WizardForm); AppNameEdit.Parent := AppQueryPage.Surface;
  AppNameEdit.Top := topPos; AppNameEdit.Left := 0; AppNameEdit.Width := AppQueryPage.SurfaceWidth;
  AppNameEdit.Text := 'MyWheelsApp'; topPos := topPos + 40;

  // Reload password
  lbl := TLabel.Create(WizardForm);
  lbl.Parent := AppQueryPage.Surface; lbl.Top := topPos; lbl.Left := 0; lbl.Width := AppQueryPage.SurfaceWidth;
  lbl.Caption := 'Reload Password:'; topPos := topPos + 16;
  ReloadPwdEdit := TEdit.Create(WizardForm); ReloadPwdEdit.Parent := AppQueryPage.Surface;
  ReloadPwdEdit.Top := topPos; ReloadPwdEdit.Left := 0; ReloadPwdEdit.Width := AppQueryPage.SurfaceWidth;
  ReloadPwdEdit.Text := 'changeMe'; topPos := topPos + 40;

  // Datasource name
  lbl := TLabel.Create(WizardForm);
  lbl.Parent := AppQueryPage.Surface; lbl.Top := topPos; lbl.Left := 0; lbl.Width := AppQueryPage.SurfaceWidth;
  lbl.Caption := 'Datasource Name:'; topPos := topPos + 16;
  DSNEdit := TEdit.Create(WizardForm); DSNEdit.Parent := AppQueryPage.Surface;
  DSNEdit.Top := topPos; DSNEdit.Left := 0; DSNEdit.Width := AppQueryPage.SurfaceWidth;
  DSNEdit.Text := 'MyWheelsApp'; topPos := topPos + 40;

  { === Page 3: Template selection === }
  TemplatesPage := CreateCustomPage(AppQueryPage.ID, 'Template Selection', 'Choose a Wheels template.');
  lbl := TLabel.Create(WizardForm); lbl.Parent := TemplatesPage.Surface; lbl.Left := 0; lbl.Top := 8;
  lbl.Width := TemplatesPage.SurfaceWidth; lbl.Caption := 'Select the template:'; topPos := 40;

  TemplateRadio1 := TRadioButton.Create(WizardForm); TemplateRadio1.Parent := TemplatesPage.Surface;
  TemplateRadio1.Left := 8; TemplateRadio1.Top := topPos; TemplateRadio1.Width := TemplatesPage.SurfaceWidth-16;
  TemplateRadio1.Caption := '3.0.x - Wheels Base Template - Bleeding Edge'; TemplateRadio1.Checked := True;
  TemplateRadio2 := TRadioButton.Create(WizardForm); TemplateRadio2.Parent := TemplatesPage.Surface;
  TemplateRadio2.Left := 8; TemplateRadio2.Top := topPos+28; TemplateRadio2.Width := TemplatesPage.SurfaceWidth-16;
  TemplateRadio2.Caption := '2.5.x - Wheels Base Template - Stable Release';
  TemplateRadio3 := TRadioButton.Create(WizardForm); TemplateRadio3.Parent := TemplatesPage.Surface;
  TemplateRadio3.Left := 8; TemplateRadio3.Top := topPos+56; TemplateRadio3.Width := TemplatesPage.SurfaceWidth-16;
  TemplateRadio3.Caption := 'Wheels Template - HTMX - Alpine.js - Simple.css';
  TemplateRadio4 := TRadioButton.Create(WizardForm); TemplateRadio4.Parent := TemplatesPage.Surface;
  TemplateRadio4.Left := 8; TemplateRadio4.Top := topPos+84; TemplateRadio4.Width := TemplatesPage.SurfaceWidth-16;
  TemplateRadio4.Caption := 'Wheels Starter App';
  TemplateRadio5 := TRadioButton.Create(WizardForm); TemplateRadio5.Parent := TemplatesPage.Surface;
  TemplateRadio5.Left := 8; TemplateRadio5.Top := topPos+112; TemplateRadio5.Width := TemplatesPage.SurfaceWidth-16;
  TemplateRadio5.Caption := 'Wheels - TodoMVC - HTMX - Demo App';

  { === Page 4: CFML Engine selection === }
  EnginePage := CreateCustomPage(TemplatesPage.ID, 'CFML Engine Selection', 'Choose which CFML engine you will use.');
  lbl := TLabel.Create(WizardForm); lbl.Parent := EnginePage.Surface; lbl.Left := 0; lbl.Top := 8; lbl.Width := EnginePage.SurfaceWidth;
  lbl.Caption := 'Select the CFML engine:'; topPos := 40;

  EngineRadio1 := TRadioButton.Create(WizardForm); EngineRadio1.Parent := EnginePage.Surface;
  EngineRadio1.Left := 8; EngineRadio1.Top := topPos; EngineRadio1.Width := EnginePage.SurfaceWidth-16; EngineRadio1.Caption := 'Lucee (Latest)'; EngineRadio1.Checked := True;
  EngineRadio2 := TRadioButton.Create(WizardForm); EngineRadio2.Parent := EnginePage.Surface;
  EngineRadio2.Left := 8; EngineRadio2.Top := topPos+28; EngineRadio2.Width := EnginePage.SurfaceWidth-16; EngineRadio2.Caption := 'Adobe ColdFusion (Latest)';
  EngineRadio3 := TRadioButton.Create(WizardForm); EngineRadio3.Parent := EnginePage.Surface;
  EngineRadio3.Left := 8; EngineRadio3.Top := topPos+56; EngineRadio3.Width := EnginePage.SurfaceWidth-16; EngineRadio3.Caption := 'Lucee 6.x';
  EngineRadio4 := TRadioButton.Create(WizardForm); EngineRadio4.Parent := EnginePage.Surface;
  EngineRadio4.Left := 8; EngineRadio4.Top := topPos+84; EngineRadio4.Width := EnginePage.SurfaceWidth-16; EngineRadio4.Caption := 'Lucee 5.x';
  EngineRadio5 := TRadioButton.Create(WizardForm); EngineRadio5.Parent := EnginePage.Surface;
  EngineRadio5.Left := 8; EngineRadio5.Top := topPos+112; EngineRadio5.Width := EnginePage.SurfaceWidth-16; EngineRadio5.Caption := 'Adobe ColdFusion 2023';
  EngineRadio6 := TRadioButton.Create(WizardForm); EngineRadio6.Parent := EnginePage.Surface;
  EngineRadio6.Left := 8; EngineRadio6.Top := topPos+140; EngineRadio6.Width := EnginePage.SurfaceWidth-16; EngineRadio6.Caption := 'Adobe ColdFusion 2021';
  EngineRadio7 := TRadioButton.Create(WizardForm); EngineRadio7.Parent := EnginePage.Surface;
  EngineRadio7.Left := 8; EngineRadio7.Top := topPos+168; EngineRadio7.Width := EnginePage.SurfaceWidth-16; EngineRadio7.Caption := 'Adobe ColdFusion 2018';

  { === Page 5: Options (H2 + Bootstrap + InitPkg) === }
  OptionsPage := CreateCustomPage(EnginePage.ID, 'Options', 'Select optional settings for your application.');
  topPos := 8;

  H2Check := TCheckBox.Create(WizardForm); H2Check.Parent := OptionsPage.Surface;
  H2Check.Left := 0; H2Check.Top := topPos; H2Check.Width := OptionsPage.SurfaceWidth;
  H2Check.Caption := 'Create and configure H2 embedded database (Lucee only).'; H2Check.Checked := False; topPos := topPos + 28;

  BootstrapCheck := TCheckBox.Create(WizardForm); BootstrapCheck.Parent := OptionsPage.Surface;
  BootstrapCheck.Left := 0; BootstrapCheck.Top := topPos; BootstrapCheck.Width := OptionsPage.SurfaceWidth;
  BootstrapCheck.Caption := 'Setup default Bootstrap settings'; BootstrapCheck.Checked := True; topPos := topPos + 28;

  InitPkgCheck := TCheckBox.Create(WizardForm); InitPkgCheck.Parent := OptionsPage.Surface;
  InitPkgCheck.Left := 0; InitPkgCheck.Top := topPos; InitPkgCheck.Width := OptionsPage.SurfaceWidth;
  InitPkgCheck.Caption := 'Initialize application as a package (create box.json)'; InitPkgCheck.Checked := True; topPos := topPos + 28;

  { === Page 6: App base path === }
  AppBaseDirPage := CreateInputDirPage(OptionsPage.ID, 'Application Installation Path', 'Choose parent folder for inetpub.', 'Default: parent of CommandBox path + \inetpub.', False, '');
  AppBaseDirPage.Add('');
  AppBaseDirPage.Values[0] := ExpandConstant('{pf}\inetpub');

  { === Page 7: Summary === }
  SummaryPage := CreateCustomPage(AppBaseDirPage.ID, 'Summary', 'Review configuration.');
  SummaryMemo := TMemo.Create(WizardForm); SummaryMemo.Parent := SummaryPage.Surface;
  SummaryMemo.Left := 0; SummaryMemo.Top := 8;
  SummaryMemo.Width := SummaryPage.SurfaceWidth-8; SummaryMemo.Height := SummaryPage.SurfaceHeight-16;
  SummaryMemo.ReadOnly := True;
end;

// --- Getter functions ---
function GetAppName(Param: String): String; begin Result := AppNameEdit.Text; end;
function GetReloadPassword(Param: String): String; begin Result := ReloadPwdEdit.Text; end;
function GetDatasource(Param: String): String; begin Result := DSNEdit.Text; end;
function GetInstallPath(Param: String): String;
begin
  Result := InstallDirPage.Values[0];
  // Append 'CommandBox' folder if user selected a custom path
  if (Result <> ExpandConstant('{pf}\CommandBox')) then Result := Result + '\CommandBox';
end;
function GetForceParam(Param: String): String; begin if ForceCheck.Checked then Result := '-Force' else Result := ''; end;
function GetSkipPathParam(Param: String): String; begin if SkipPathCheck.Checked then Result := '-SkipPath' else Result := ''; end;
function GetUseH2Param(Param: String): String; begin if H2Check.Checked then Result := '-UseH2' else Result := ''; end;
function GetBootstrapParam(Param: String): String; begin if BootstrapCheck.Checked then Result := '-UseBootstrap' else Result := ''; end;
function GetInitPkgParam(Param: String): String; begin if InitPkgCheck.Checked then Result := '-InitializeAsPackage' else Result := ''; end;
function GetAppBasePath(Param: String): String;
begin
  Result := AppBaseDirPage.Values[0];
  if (Result = ExpandConstant('{pf}\inetpub')) then
    Result := ExtractFileDir(GetInstallPath('')) + '\inetpub';
end;

// --- Template & Engine getters ---
function GetTemplate(Param: String): String;
begin
  if TemplateRadio1.Checked then Result := 'wheels-base-template@BE'
  else if TemplateRadio2.Checked then Result := 'wheels-base-template@stable'
  else if TemplateRadio3.Checked then Result := 'wheels-htmx-template'
  else if TemplateRadio4.Checked then Result := 'wheels-starter-template'
  else Result := 'wheels-todomvc-template';
end;

function GetEngine(Param: String): String;
begin
  if EngineRadio1.Checked then Result := 'lucee'
  else if EngineRadio2.Checked then Result := 'adobe'
  else if EngineRadio3.Checked then Result := 'lucee@6'
  else if EngineRadio4.Checked then Result := 'lucee@5'
  else if EngineRadio5.Checked then Result := 'adobe@2023'
  else if EngineRadio6.Checked then Result := 'adobe@2021'
  else Result := 'adobe@2018';
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  { Dynamically update AppBaseDir default path based on selected CommandBox path }
  if CurPageID = AppBaseDirPage.ID then
  begin
    if AppBaseDirPage.Values[0] = ExpandConstant('{pf}\inetpub') then
      AppBaseDirPage.Values[0] := ExtractFileDir(GetInstallPath('')) + '\inetpub';
  end;

  { Populate summary page }
  if CurPageID = SummaryPage.ID then
  begin
    SummaryMemo.Lines.Clear;
    SummaryMemo.Lines.Add('Configuration summary:');
    SummaryMemo.Lines.Add('----------------------------------------');
    SummaryMemo.Lines.Add('CommandBox path: ' + InstallDirPage.Values[0]);
    if ForceCheck.Checked then SummaryMemo.Lines.Add('Force reinstall CommandBox: Yes') else SummaryMemo.Lines.Add('Force reinstall CommandBox: No');
    if SkipPathCheck.Checked then SummaryMemo.Lines.Add('Skip adding CommandBox to PATH: Yes') else SummaryMemo.Lines.Add('Skip adding CommandBox to PATH: No');
    SummaryMemo.Lines.Add('');
    SummaryMemo.Lines.Add('Application name: ' + AppNameEdit.Text);
    SummaryMemo.Lines.Add('Reload password: ' + ReloadPwdEdit.Text);
    SummaryMemo.Lines.Add('Datasource name: ' + DSNEdit.Text);
    SummaryMemo.Lines.Add('Template: ' + GetTemplate(''));
    SummaryMemo.Lines.Add('CFML Engine: ' + GetEngine(''));
    if H2Check.Checked then SummaryMemo.Lines.Add('Use H2 DB: Yes') else SummaryMemo.Lines.Add('Use H2 DB: No');
    if BootstrapCheck.Checked then SummaryMemo.Lines.Add('Setup Bootstrap: Yes') else SummaryMemo.Lines.Add('Setup Bootstrap: No');
    if InitPkgCheck.Checked then SummaryMemo.Lines.Add('Initialize as package: Yes') else SummaryMemo.Lines.Add('Initialize as package: No');
    SummaryMemo.Lines.Add('');
    SummaryMemo.Lines.Add('Application base path: ' + AppBaseDirPage.Values[0]);
    SummaryMemo.Lines.Add('----------------------------------------');
  end;
end;

// --- Validation helper ---
function IsValidIdentifier(const S: String): Boolean;
var
  i: Integer;
  c: Char;
begin
  Result := True;

  if S = '' then
  begin
    Result := False;
    Exit;
  end;

  for i := 1 to Length(S) do
  begin
    c := S[i];
    if not (
      ((c >= 'A') and (c <= 'Z')) or
      ((c >= 'a') and (c <= 'z')) or
      ((c >= '0') and (c <= '9')) or
      (c = '-') or (c = '_')
    ) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

// --- Validation hook ---
function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = AppQueryPage.ID then
  begin
    if not IsValidIdentifier(AppNameEdit.Text) then
    begin
      MsgBox('Invalid Application Name. (Only letters, numbers, "-" and "_" are allowed.)',
        mbError, MB_OK);
      Result := False;
    end
    else if not IsValidIdentifier(DSNEdit.Text) then
    begin
      MsgBox('Invalid Datasource Name. (Only letters, numbers, "-" and "_" are allowed.)',
        mbError, MB_OK);
      Result := False;
    end;
  end;
end;