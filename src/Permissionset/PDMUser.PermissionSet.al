/// <summary>
/// This permission set gives the R(eading) permission to necessary PDM objects
/// </summary>
permissionset 70647566 "PDM User OKE97"
{
    Assignable = true;
    Caption = 'PDM user';

    Permissions =
        tabledata "PDM API Key OKE97" = r,
        tabledata "PDM Setup OKE97" = r,
        tabledata "PDM Temp Blob OKE97" = r,
        table "PDM API Key OKE97" = x,
        table "PDM Setup OKE97" = x,
        table "PDM Temp Blob OKE97" = x,
        codeunit "PDM Foundation OKE97" = x,
        page "PDM API Key List OKE97" = X;
}
