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
        UsersInPlans: Query "Users in Plans";
        PickExistsErr: Label 'This Sales Order cannot be reopened because a Warehouse Pick has already been created for it.';
        IsDeliveryUser: Boolean;
    begin
        if not GuiAllowed then
            exit;

        if SalesOrderNo = '' then exit;

        UsersInPlans.SetFilter(User_Security_ID, '%1', UserSecurityId());
        UsersInPlans.Open();
        while UsersInPlans.Read() do begin
            if UsersInPlans.Plan_Name.Contains('Premium') then
                IsDeliveryUser := true;
        end;
        UsersInPlans.Close();

        if IsDeliveryUser then
            exit;

        WhseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WhseActivityLine.SetRange("Source Subtype", 1); // 1 = Sales Order
        WhseActivityLine.SetRange("Source No.", SalesOrderNo);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);

        if not WhseActivityLine.IsEmpty then
            Error(PickExistsErr);
    end;
}