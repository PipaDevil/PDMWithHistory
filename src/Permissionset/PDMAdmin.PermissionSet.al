/// <summary>
/// This permission set gives RIMD or X permissions to all PDM objects
/// </summary>
permissionset 70647565 "PDM Admin OKE97"
{
    Assignable = true;
    Caption = 'PDM administrator';

    Permissions =
        tabledata "PDM API Key OKE97" = RIMD,
        tabledata "PDM Setup OKE97" = RIMD,
        tabledata "PDM Temp Blob OKE97" = rimd,
        table "PDM API Key OKE97" = X,
        table "PDM Setup OKE97" = X,
        table "PDM Temp Blob OKE97" = x,
        codeunit "PDM Foundation OKE97" = X,
        page "PDM API Key List OKE97" = X,
        page "PDM Setup OKE97" = X;
}