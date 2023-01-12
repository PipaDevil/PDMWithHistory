/// <summary>
/// Enum that provides information about the status of the extension
/// </summary>
enum 70647567 "PDM Status OKE97"
{    
    value(0; "Fresh install")
    {
        Caption = 'Fresh install';
    }
    value(1; "Verification required")
    {
        Caption = 'Verification required';
    }
    value(2; Verified)
    {
        Caption = 'Verified';
    }
    value(3; "Connection failed")
    {
        Caption = 'Connection failed';
    }
    value(4; "Verification failed")
    {
        Caption = 'Verification failed';
    }
    value(5; Disabled)
    {
        Caption = 'Disabled';
    }
    value(6; "Grace period active")
    {
        Caption = 'Grace period active';
    }
    value(7; "Grace period exceeded")
    {
        Caption = 'Grace period exceeded';
    }
}
