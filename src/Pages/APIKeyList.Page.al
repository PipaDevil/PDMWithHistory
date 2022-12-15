page 70647565 "API Key List OKE97"
{
    ApplicationArea = All;
    Caption = 'API Key List OKE97';
    PageType = List;
    SourceTable = "API Key OKE97";
    UsageCategory = Lists;
    
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(ReportId; Rec.ReportId)
                {
                    ToolTip = 'Specifies the value of the ReportId field.';
                }
                field(Apikey; Rec.Apikey)
                {
                    ToolTip = 'Specifies the value of the Apikey field.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                }
            }
        }
    }
}
