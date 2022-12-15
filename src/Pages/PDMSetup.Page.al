page 70647566 "PDM Setup OKE97"
{
    ApplicationArea = Administration;
    Caption = 'Setup OKE97';
    PageType = Card;
    SourceTable = "PDM Setup OKE97";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(AlwaysRunMerge; Rec.AlwaysRunMerge)
                {
                    ToolTip = 'Specifies the value of the Setting field.';
                }
                field(DefaultApiKey;Rec.DefaultApiKey)
                {
                    ToolTip = 'Specifies the value of the DefaultApiKey field.';
                    Enabled = Rec.AlwaysRunMerge;
                }
            }
        }
    }
}
