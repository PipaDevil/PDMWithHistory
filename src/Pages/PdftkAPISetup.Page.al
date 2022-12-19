page 70647566 "Pdftk API Setup OKE97"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Setup OKE97';
    PageType = Card;
    SourceTable = "Pdftk API setup OKE97";
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
