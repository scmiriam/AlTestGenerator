codeunit 70829 "DTNGAR ReversalEntry"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        DTNGARGuarantee: Record "DTNGAR Guarantee";
        DTNGARGuaranteeEntry: Record "DTNGAR Guarantee Entry";
        DTNGARSetup: Record "DTNGAR Setup";
        PurchaseOrderHeader: Record "Purchase Header";
        GuaranteesLibrary: Codeunit "DTNGAR Guarantees Library";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LastBankEntry: Integer;
        LastCustLedgerEntry: Integer;
        LastDetCustLedEntry: Integer;
        LastGLEntry: Integer;
        LastledgerGuarantees: Integer;
        CustLedgerEntries: TestPage "Customer Ledger Entries";
        DTNGARBond: TestPage "DTNGAR Bond Card";
        LibraryInventory: Codeunit "Library - Inventory";
        UnitOfMeasure: Record "Unit of Measure";

    [ModalPageHandler]
    procedure ModalPageHandler(VAR DTNGARBankGuaranteeCard: TestPage "DTNGAR Bank Guarantee Card")
    begin
        DTNGARBankGuaranteeCard.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure ModalPageHandler39(VAR GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure ModalPageHandler250(VAR GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.OK().INVOKE();
    end;

    [ModalPageHandler]
    procedure ModalPageHandler179(var ReverseEntry: TestPage "Reverse Transaction Entries");
    begin
        ReverseEntry.Reverse.Invoke();
    end;

    [RequestPageHandler]
    procedure RPHPostGuarantee(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        GuaranteeAccountGroup: Record "DTNGAR Account Group";
        ActionType: Enum "DTNGAR PostTypeProcess";
        EntryType: Enum "DTNGAR EntryTypePostProcess";
        SeizeType: Enum "DTNGAR SeizureTypePostProcess";
    begin
        GuaranteeAccountGroup.get(DTNGARGuarantee."Account Group");
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(10000, 40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Account);
                    if DTNGARGuarantee.Term = DTNGARGuarantee.Term::Short then
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Short-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Short-Term Account (Deposited)")
                    else
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Long-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Long-Term Account (Deposited)");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Account);
                    if DTNGARGuarantee.Term = DTNGARGuarantee.Term::Short then
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Short-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Short-Term Account (Deposited)")
                    else
                        if DTNGARGuarantee."Guarantee Type" = DTNGARGuarantee."Guarantee Type"::Received then
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Long-Term Account (Received)")
                        else
                            RequestPage.Account.SetValue(GuaranteeAccountGroup."Long-Term Account (Deposited)");
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Reclassify):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.IsTransactionPurposal.SetValue(true);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
        end;
    end;


    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    Procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [Test]
    [HandlerFunctions('RPHPostGuarantee,MessageHandler,ModalPageHandler39,ConfirmHandler,ModalPageHandler179')]
    procedure ReverseLedgerEntry()
    var

    begin
        // [Escenario] Inicializar escenario
        GuaranteesLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteesLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        GuaranteesLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);
        // [Condiciones] No hay

        // [Ejecucion]

        //DEPOSITO
        GuaranteesLibrary.DeleteJournalLine();
        GuaranteesLibrary.RunDepositGuarantee(DTNGARGuarantee);
        GuaranteesLibrary.PostJournalLine();

        DTNGARBond.OpenEdit();
        DTNGARBond.GoToRecord(DTNGARGuarantee);
        GuaranteesLibrary.CheckAmountAfterDeposit(DTNGARBond);
        DTNGARBond.Close();

        GuaranteesLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteesLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteesLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteesLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteesLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //DEVOLUCION
        GuaranteesLibrary.DeleteJournalLine();
        GuaranteesLibrary.RunRetunrGuarantee(DTNGARGuarantee);
        GuaranteesLibrary.PostJournalLine();

        DTNGARBond.OpenEdit();
        DTNGARBond.GoToRecord(DTNGARGuarantee);
        GuaranteesLibrary.CheckAmountsAfterReturn(DTNGARBond);
        DTNGARBond.Close();

        GuaranteesLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteesLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Return);
        GuaranteesLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteesLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteesLibrary.InitLastLedgerEntries(LastledgerGuarantees, LastGLEntry, LastBankEntry, LastCustLedgerEntry, LastDetCustLedEntry);

        //INCAUTACION
        GuaranteesLibrary.DeleteJournalLine();
        GuaranteesLibrary.RunRunGuarantee(DTNGARGuarantee);
        GuaranteesLibrary.PostJournalLine();

        DTNGARBond.OpenEdit();
        DTNGARBond.GoToRecord(DTNGARGuarantee);
        GuaranteesLibrary.CheckAmountAfterRun(DTNGARBond);
        DTNGARBond.Close();

        GuaranteesLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteesLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Seizure);
        GuaranteesLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteesLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        //RECLASIFICACION
        GuaranteesLibrary.DeleteJournalLine();
        GuaranteesLibrary.RunReclasGuarantee(DTNGARGuarantee);
        GuaranteesLibrary.PostJournalLine();

        DTNGARBond.OpenEdit();
        DTNGARBond.GoToRecord(DTNGARGuarantee);
        GuaranteesLibrary.CheckFieldsAfterReclas(DTNGARBond);
        DTNGARBond.Close();

        GuaranteesLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteesLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Reclassification);
        GuaranteesLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteesLibrary.CheckGuaranteesDate(DTNGARGuarantee);


        // [Comprobacion]
        CustLedgerEntry.SetRange("Document No.", DTNGARGuarantee."No.");
        if CustLedgerEntry.FindFirst() then begin
            //Abrir página mov cliente
            //seleccionar movimiento para revertir transaccion
            CustLedgerEntries.OpenEdit();
            CustLedgerEntries.Expand(true);
            CustLedgerEntries.GoToRecord(CustLedgerEntry);
            CustLedgerEntries.ReverseTransaction.Invoke();
        end;
    end;
}