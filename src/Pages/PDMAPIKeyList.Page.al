/// <summary>
/// Page PDM API Key List OKE97 (ID 70647565)
/// Provides users with a list of currently enabled API keys, and the report it's enabled for.
/// </summary>
page 70647565 "PDM API Key List OKE97"
{
    ApplicationArea = Basic, Suite;
    Caption = 'PDM API Key List';
    PageType = List;
    SourceTable = "PDM API Key OKE97";
    UsageCategory = Administration;
    Permissions =
        tabledata "PDM Setup OKE97" = R;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(ReportId; Rec.ReportId)
                {
                    ToolTip = 'Specifies the value of the ReportId field.';
                    Enabled = AllowEditReportId;
                }
                field(ReportName; Rec.ReportName)
                {
                    ToolTip = 'Specifies the value of the ReportName field.';
                }
                field(Apikey; Rec.Apikey)
                {
                    ToolTip = 'Specifies the value of the Apikey field.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'The status of the most recent use of this key.';
                    Enabled = false;
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action("Open PDM Setup page")
            {
                Caption = 'Open PDM Setup page';
                ToolTip = 'Opens the PDM Setup page';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                RunObject = Page "PDM Setup OKE97";
            }
        }
    }

    var
        PdmSetup: Record "PDM Setup OKE97";
        [InDataSet]
        AllowEditReportId: Boolean;

    trigger OnOpenPage()
    begin
        PdmSetup.FindSet();
        AllowEditReportId := PdmSetup.AllowEditReportId;
    end;
}
