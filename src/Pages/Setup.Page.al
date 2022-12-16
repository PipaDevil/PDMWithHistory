page 70647566 "PDM Setup OKE97"
{
    ApplicationArea = Administration;
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
            }
            group(API)
            {
                Caption = 'API';
                field(BackgroundMergeUrl; Rec.BackgroundMergeUrl)
                {
                    ToolTip = 'The URL to send background merge requests to.';
                    Enabled = Rec.UsePDM;
                }

                field(UseDefaultApiKey; Rec.UseDefaultApiKey)
                {
                    ToolTip = 'Specifies if the extension should use a default API key if there is no key specified for the report being run.';
                    Enabled = Rec.UsePDM;
                }
                field(DefaultApiKey; Rec.DefaultApiKey)
                {
                    ToolTip = 'Specifies the value of the default API key.';
                    Enabled = Rec.UsePDM and Rec.UseDefaultApiKey;
                }
            }
        }
    }
    actions
    {
        area(Creation)
        {
            action("Open API key list")
            {
                Caption = 'Open API key list';
                Image = ListPage;
                Promoted = true;
                ApplicationArea = Administration;
                RunObject = Page "PDM API Key List OKE97";
            }
        }
    }
}
