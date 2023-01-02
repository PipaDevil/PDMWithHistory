/// <summary>
/// This permission set enables a basic user to call the PDM functions
/// </summary>
permissionset 70647566 "PDM User OKE97"
{
    Assignable = true;
    Caption = 'PDM user';

    Permissions =
        tabledata "PDM Setup OKE97" = r,
        tabledata "PDM API Key OKE97" = rim,
        tabledata "PDM Temp Blob OKE97" = rim,
        table "PDM API Key OKE97" = x,
        table "PDM Setup OKE97" = x,
        table "PDM Temp Blob OKE97" = x,
        codeunit "PDM Foundation OKE97" = x;
}
