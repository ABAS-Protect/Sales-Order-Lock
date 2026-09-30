/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-09-28
    Description: Prevent sales staff from reopening released sales order with warehouse activity.
*/
codeunit 50103 "SalesOrderLock"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeReopenSalesDoc', '', false, false)]
    local procedure OnBeforeReopenSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.IsTemporary then exit;
        CheckIfPickExistsAndUserBlocked(SalesHeader."No.");
    end;

    local procedure CheckIfPickExistsAndUserBlocked(SalesOrderNo: Code[20])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        PickExistsErr: Label 'This Sales Order cannot be reopened because a Warehouse Pick has already been created for it.';
    begin
        if not GuiAllowed then
            exit;

        if SalesOrderNo = '' then exit;

        if CheckIfPremiumUser() then
            exit;

        WhseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WhseActivityLine.SetRange("Source Subtype", 1); // 1 = Sales Order
        WhseActivityLine.SetRange("Source No.", SalesOrderNo);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);

        if not WhseActivityLine.IsEmpty then
            Error(PickExistsErr);
    end;

    local procedure CheckIfPremiumUser(): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'D365 BUS PREMIUM');
        // AccessControl.SetFilter("Company Name", '%1|%2', '', CompanyName());

        exit(not AccessControl.IsEmpty());
    end;
}