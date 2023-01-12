pageextension 70647565 "PDM Rolecenter OKE97" extends "Administrator Role Center"
{
    Caption = 'PDM Rolecenter';
    Description = 'PDM';
    Editable = false;

    actions
    {
        addlast(sections)
        {
            group("PDM OKE97")
            {
                Caption = 'PDM';

                action("PDM Setup OKE97")
                {
                    Caption = 'PDM Setup';
                    RunObject = Page "PDM Setup OKE97";
                    Image = Administration;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Executes the PDM Setup action.';
                }
                action("PDM API Key List OKE97")
                {
                    Caption = 'PDM API Key List';
                    RunObject = Page "PDM API Key List OKE97";
                    Image = List;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Executes the PDM API Key List action.';
                }
            }
        }
    }
}