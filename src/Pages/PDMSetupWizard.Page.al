/// <summary>
/// PDM Setup Wizard
/// </summary>
page 70647567 "PDM Setup Wizard OKE97"
{
    Caption = 'PDM Setup Wizard';
    PageType = NavigatePage;
    SourceTable = "PDM Setup OKE97";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(StandardBanner)
            {
                Caption = 'StandardBanner';
                Editable = false;
                Visible = TopBannerVisible and not FinishActionEnabled;
                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(FinishedBanner)
            {
                Caption = 'FinishedBanner';
                Editable = false;
                Visible = TopBannerVisible and FinishActionEnabled;
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Visible = Step1Visible;

                group("Welcome to PDM")
                {
                    Caption = 'Welcome to the PDM setup wizard!';
                    InstructionalText = 'Make adding custom backgrounds to your reports easier by connecting Business Central to the PDM API.';
                }

                group("Let's go")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to get started.';
                }
            }

            group(Step2)
            {
                Visible = Step2Visible;

                group("License key")
                {
                    Caption = 'License key';
                    InstructionalText = 'Insert your API license key.';

                    field(ApiLicenseKey; Rec.ApiLicenseKey)
                    {
                        ApplicationArea = All;
                    }

                    group(LKDesc)
                    {
                        Caption = 'No license key?';
                        InstructionalText = 'Open the webshop with the button below.';
                    }
                }
            }

            group(Step3)
            {
                Visible = Step3Visible;
                Caption = 'Finished setting up PDM! 🥳';
                InstructionalText = 'For further settings, visit the PDM Setup page. Select Finish to save the license key!';

            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenWebshop)
            {
                ApplicationArea = All;
                Image = LinkWeb;
                Caption = 'Open webshop';
                Enabled = true;
                Visible = ShowWebshopAction;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Message('https://webshop.one-it.nl');
                    // Hyperlink('https://webshop.one-it.nl');
                end;
            }
        }
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Insert();

        Step := Step::Start;
        EnableControls();
    end;

    var
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        Step: Option Start,Step2,Finish;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        ShowWebshopAction: Boolean;

    local procedure NextStep(Backwards: Boolean);
    begin
        if Step = Step::Step2 then
            Rec.Testfield(ApiLicenseKey);

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure EnableControls();
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStep1();
            Step::Step2:
                ShowStep2();
            Step::Finish:
                ShowStep3();
        end;
    end;

    local procedure ShowStep1();
    begin
        Step1Visible := true;

        FinishActionEnabled := false;
        BackActionEnabled := false;
        ShowWebshopAction := false;
    end;

    local procedure ShowStep2();
    begin
        Step2Visible := true;
        ShowWebshopAction := true;
    end;

    local procedure ShowStep3();
    begin
        Step3Visible := true;

        NextActionEnabled := false;
        FinishActionEnabled := true;
        ShowWebshopAction := false;
    end;

    local procedure ResetControls();
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        Step1Visible := false;
        Step2Visible := false;
        Step3Visible := false;
    end;

    local procedure FinishAction();
    begin
        StoreRecordVar();
        OnCompletePdmSetupWizard();
        CurrPage.Close();
    end;

    local procedure StoreRecordVar();
    var
        ApiVersion: Enum "PDM API Versions OKE97";
        PdmSetup: Record "PDM Setup OKE97";
        Company: Record Company;
        CompanyId: Guid;
    begin
        if not PdmSetup.Get() then begin
            PdmSetup.Init();
            PdmSetup.Insert();
        end;

        Company.Get(CompanyName());
        CompanyId := Company.SystemId;
        Rec.CompanyId := CompanyId;

        Rec.UsePDM := true;
        Rec.ApiVersion := ApiVersion::v1;
        Rec.Status := "PDM Status OKE97"::"Setup done";
        PdmSetup.TransferFields(Rec, false);
        PdmSetup.Modify(true);
    end;

    var
        MediaRepositoryDone: Record "Media Repository";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesDone: Record "Media Resources";
        MediaResourcesStandard: Record "Media Resources";
        TopBannerVisible: Boolean;

    trigger OnInit();
    begin
        LoadTopBanners();
    end;

    local procedure LoadTopBanners();
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and
            MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
                MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
        then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCompletePdmSetupWizard()
    begin
    end;
}
