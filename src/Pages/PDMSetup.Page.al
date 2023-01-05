/// <summary>
/// Page PDM Setup OKE97 (ID 70647566).
/// </summary>
page 70647566 "PDM Setup OKE97"
{
    ApplicationArea = Basic;
    Caption = 'PDM Setup';
    PageType = Card;
    SourceTable = "PDM Setup OKE97";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(UsePDM; Rec.UsePDM)
                {
                    ToolTip = 'Global toggle option for the entire PDM extension.';
                }
                field(AllowEditReportId; Rec.AllowEditReportId)
                {
                    ToolTip = 'Whether or not you can manually insert reports by ID into the list of API keys.';
                    Enabled = Rec.UsePDM;
                }
                field(ApiLicenseKey; Rec.ApiLicenseKey)
                {
                    ToolTip = 'License key, required to verify your requests on the external API. PDM will be toggled off in case of invalid license.';
                    Enabled = Rec.UsePDM;
                }
            }
            group(API)
            {
                Caption = 'API';
                field(ApiVersion; Rec.ApiVersion)
                {
                    ToolTip = 'The version of the external API to use.';
                    Enabled = Rec.UsePDM;
                }

                field(UseDefaultApiKey; Rec.UseDefaultApiKey)
                {
                    ToolTip = 'Specifies if the extension should use a default API key if there is no key specified for the report being run.';
                    Enabled = Rec.UsePDM;
                }
                field(DefaultApiKey; Rec.DefaultApiKey)
                {
                    ToolTip = 'Specifies the default API key to use.';
                    Enabled = Rec.UsePDM and Rec.UseDefaultApiKey;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Open API key list")
            {
                Caption = 'Open API key list';
                Image = ListPage;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                RunObject = Page "PDM API Key List OKE97";
            }
            action("Check License Date")
            {
                Caption = 'Check License Date';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;

                trigger OnAction()
                var
                    PdmFoundation: Codeunit "PDM Foundation OKE97";
                    StatusNotification: Notification;
                begin
                    if not PdmFoundation.LicenseHasBeenChecked() then begin
                        StatusNotification.Message := 'License has not yet been checked today.';
                        StatusNotification.AddAction('Verify license', Codeunit::"PDM Foundation OKE97", 'ManualLicenseVerification');
                    end else begin
                        StatusNotification.Message := 'License has already been successfully checked today.';
                    end;
                    StatusNotification.Send();
                end;
            }
        }
    }

    var
        PdmStatus: Enum "PDM Status OKE97";

    trigger OnOpenPage()
    var
        PdmSetup: Record "PDM Setup OKE97";
    begin
        if not PdmSetup.Get() then
            Page.RunModal(Page::"PDM Setup Wizard OKE97");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if (Rec.Status = PdmStatus::"Fresh install") then
            Page.RunModal(Page::"PDM Setup Wizard OKE97");

        if not (Rec.Status = PdmStatus::Verified) then
            DisplayStatusNotification();
    end;

    local procedure DisplayStatusNotification()
    var
        StatusNotification: Notification;
        NotificationMessage: Text;
    begin
        StatusNotification.Message := Format(Rec.Status);
        case Rec.Status of
            PdmStatus::"Connection failed":
                begin
                    NotificationMessage := 'PDM wont work, because the most recent license verification attempt failed.';
                    StatusNotification.AddAction('Retry license verification', Codeunit::"PDM Foundation OKE97", 'ManualLicenseVerification');
                end;
            PdmStatus::"Setup done":
                begin
                    NotificationMessage := 'PDM is almost ready to be used, verify your license to get started!';
                    StatusNotification.AddAction('Verify license', Codeunit::"PDM Foundation OKE97", 'ManualLicenseVerification');
                end;
            PdmStatus::Disabled:
                begin
                    NotificationMessage := 'PDM is currently disabled, switch it on to get started.';
                end;
            PdmStatus::"Verification failed":
                begin
                    NotificationMessage := 'PDM wont work, because the license is invalid.';
                    StatusNotification.AddAction('Retry license verificaton', Codeunit::"PDM Foundation OKE97", 'ManualLicenseVerification');
                end;
        end;

        StatusNotification.Message := NotificationMessage;
        StatusNotification.Scope := NotificationScope::LocalScope;
        StatusNotification.Send();
    end;
}
