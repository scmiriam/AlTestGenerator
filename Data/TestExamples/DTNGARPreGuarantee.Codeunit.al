codeunit 70822 "DTNGAR PreGuarantee"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Customer: Record Customer;
        DTNGARSetup: Record "DTNGAR Setup";
        GuaranteeLibrary: Codeunit "DTNGAR Guarantees Library";
        LibrarySales: Codeunit "Library - Sales";

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text; var Reply: Boolean)
    begin
        Reply := False;
    end;

    [MessageHandler]
    Procedure MessageHandler(Msg: Text[1024])
    begin

    end;

    [PageHandler]
    procedure PageHandlerAval(VAR DTNGARBankGuaranteeCard: Page "DTNGAR Bank Guarantee Card")
    begin
        DTNGARBankGuaranteeCard.SaveRecord();
    end;

    [PageHandler]
    procedure PageHandlerFianza(VAR DTNGARBond: Page "DTNGAR Bond Card")
    begin
        DTNGARBond.SaveRecord();
    end;

    [Test]
    procedure CreatePreGuarantee()
    var
        DTNGARGuarantee: Record "DTNGAR Guarantee";
        GuaranteesList: Page "DTNGAR Pre Guarantees";
    begin
        // [Escenario] Inicializar escenario
        GuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        // [Condiciones] No hay


        // [Ejecucion]
        GuaranteeLibrary.CreateGuarantee(DTNGARGuarantee, Customer."No.", DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup);
        // [Comprobacion]
        GuaranteesList.SetRecord(DTNGARGuarantee);
    end;

    [Test]
    [HandlerFunctions('PageHandlerGuarantees456True')]
    procedure ConvertGuaranteeInBankGuaranteeDefinitiveAssistEdit()
    var
        DTNGARGuaranteeBankGuaratee: Record "DTNGAR Guarantee";
        DTNGARPreGuaranteeCard: TestPage "DTNGAR Pre Guarantee";
    begin
        // [Escenario] Inicializar escenario
        GuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        DTNGARGuaranteeBankGuaratee.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        // [Condiciones] No hay

        // [Ejecucion]
        GuaranteeLibrary.CreateGuarantee(DTNGARGuaranteeBankGuaratee, Customer."No.", DTNGARGuaranteeBankGuaratee."Guaranteed Type"::Customer, DTNGARSetup);

        // [Comprobacion]
        DTNGARPreGuaranteeCard.OpenEdit();
        DTNGARPreGuaranteeCard.GoToRecord(DTNGARGuaranteeBankGuaratee);
        DTNGARPreGuaranteeCard.New();
        DTNGARPreGuaranteeCard."No.".AssistEdit();
        DTNGARPreGuaranteeCard.OK().Invoke();

    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PageHandlerAval')]
    procedure ConvertGuaranteeInBankGuaranteeDefinitive()
    var
        DTNGARGuaranteeBankGuaratee: Record "DTNGAR Guarantee";
        DTNGARPrelGuaranteeCard: TestPage "DTNGAR Pre Guarantee";
        DTNGARBankGuaranteeCard: TestPage "DTNGAR Bank Guarantee Card";


    begin
        // [Escenario] Inicializar escenario
        GuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        DTNGARGuaranteeBankGuaratee.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        // [Condiciones] No hay
        GuaranteeLibrary.CreateGuarantee(DTNGARGuaranteeBankGuaratee, Customer."No.", DTNGARGuaranteeBankGuaratee."Guaranteed Type"::Customer, DTNGARSetup);

        // [Ejecucion]
        DTNGARPrelGuaranteeCard.OpenEdit();
        DTNGARPrelGuaranteeCard.GoToRecord(DTNGARGuaranteeBankGuaratee);
        DTNGARPrelGuaranteeCard.MakeBankGuarantee.Invoke();
        // [Comprobacion]
        DTNGARGuaranteeBankGuaratee.FindLast();
        DTNGARBankGuaranteeCard.OpenEdit();
        DTNGARBankGuaranteeCard.GoToRecord(DTNGARGuaranteeBankGuaratee);
    end;

    [ModalPageHandler]
    procedure PageHandlerGuarantees456True(var EditSeries: TestPage "No. Series");
    begin
        EditSeries.Ok().Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PageHandlerFianza')]
    procedure ConvertGuaranteeInGuaranteeDefinitive()
    var
        DTNGARCodesSetup: Record "DTNGAR Codes Setup";
        DTNGARGuaranteeBond: Record "DTNGAR Guarantee";
        DTNGARBond: TestPage "DTNGAR Bond Card";
        DTNGARPreGuaranteeCard: TestPage "DTNGAR Pre Guarantee";
    begin
        // [Escenario] Inicializar escenario
        GuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        DTNGARGuaranteeBond.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        DTNGARCodesSetup.DeleteAll();
        DTNGARCodesSetup.Validate(Type, DTNGARCodesSetup.Type::"Guarantee Sort");
        DTNGARCodesSetup.Validate(Code, 'code');
        DTNGARCodesSetup.Validate(Description, 'code');
        DTNGARCodesSetup.Insert(true);
        // [Condiciones] 
        GuaranteeLibrary.CreateGuarantee(DTNGARGuaranteeBond, Customer."No.", DTNGARGuaranteeBond."Guaranteed Type"::Customer, DTNGARSetup);
        DTNGARGuaranteeBond.Validate(DTNGARGuaranteeBond."Guarantee Sort", 'code');
        DTNGARGuaranteeBond.Modify(true);
        Commit();
        // [Ejecucion]
        DTNGARPreGuaranteeCard.OpenEdit();
        DTNGARPreGuaranteeCard.GoToRecord(DTNGARGuaranteeBond);
        DTNGARPreGuaranteeCard.MakeBond.Invoke();

        // [Comprobacion]
        DTNGARGuaranteeBond.FindLast();
        DTNGARBond.OpenEdit();
        DTNGARBond.GoToRecord(DTNGARGuaranteeBond);
    end;


    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure ConvertGuaranteeInGuaranteeDefinitiveTest1()
    var
        DTNGARCodesSetup: Record "DTNGAR Codes Setup";
        DTNGARGuaranteeBond: Record "DTNGAR Guarantee";
        DTNGARPreGuaranteeCard: TestPage "DTNGAR Pre Guarantee";
    begin
        // [Escenario] Inicializar escenario
        GuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        DTNGARGuaranteeBond.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        DTNGARCodesSetup.DeleteAll();
        DTNGARCodesSetup.Validate(Type, DTNGARCodesSetup.Type::"Guarantee Sort");
        DTNGARCodesSetup.Validate(Code, 'code');
        DTNGARCodesSetup.Validate(Description, 'code');
        DTNGARCodesSetup.Insert(true);
        // [Condiciones] 
        GuaranteeLibrary.CreateGuarantee(DTNGARGuaranteeBond, Customer."No.", DTNGARGuaranteeBond."Guaranteed Type"::Customer, DTNGARSetup);
        DTNGARGuaranteeBond.Validate(DTNGARGuaranteeBond."Guarantee Sort", 'code');
        DTNGARGuaranteeBond.Modify(true);
        Commit();
        // [Ejecucion]
        DTNGARPreGuaranteeCard.OpenEdit();
        DTNGARPreGuaranteeCard.GoToRecord(DTNGARGuaranteeBond);
        DTNGARPreGuaranteeCard.MakeBond.Invoke();

    end;


}