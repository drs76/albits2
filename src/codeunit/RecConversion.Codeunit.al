/// <summary>
/// Codeunit PTERecConversion (ID 50101).
/// Functions to convert records.
/// </summary>
codeunit 50101 PTERecConversion
{

    /// <summary>
    /// ToJson.
    /// </summary>
    /// <param name="RecordToConvert">Variant.</param>
    /// <returns>Return variable ReturnValue of type JsonObject.</returns>
    procedure ToJson(RecordToConvert: Variant) ReturnValue: JsonObject
    begin
        exit(ToJson(RecordToConvert, false));
    end;

    /// <summary>
    /// ToJson.
    /// </summary>
    /// <param name="RecordToConvert">Variant.</param>
    /// <param name="UseSystemFields">Boolean.</param>
    /// <returns>Return variable ReturnValue of type JsonObject.</returns>
    procedure ToJson(RecordToConvert: Variant; UseSystemFields: Boolean) ReturnValue: JsonObject
    var
        Fields: Record Field;
        RecRef: RecordRef;
        WrongTypeErr: Label 'RecordToConvert must be type Recored.';
    begin
        if not RecordToConvert.IsRecord() then
            Error(WrongTypeErr);

        RecRef.GetTable(RecordToConvert);
        if not GetFields(RecRef.Number(), Fields, UseSystemFields) then
            exit;

        ProcessToJson(RecRef, Fields, ReturnValue);
    end;

    /// <summary>
    /// ToXml.
    /// </summary>
    /// <param name="RecordToConvert">Variant.</param>
    /// <param name="UseSystemFields">Boolean.</param>
    /// <returns>Return variable ReturnValue of type XmlDocument.</returns>
    procedure ToXml(RecordToConvert: Variant; UseSystemFields: Boolean) ReturnValue: XmlDocument
    var
        Fields: Record Field;
        RecRef: RecordRef;
        WrongTypeErr: Label 'RecordToConvert must be type Recored.';
    begin
        if not RecordToConvert.IsRecord() then
            Error(WrongTypeErr);

        RecRef.GetTable(RecordToConvert);
        if not GetFields(RecRef.Number(), Fields, UseSystemFields) then
            exit;

        ProcessToXml(RecRef, Fields, ReturnValue);
    end;

    /// <summary>
    /// ToXml.
    /// </summary>
    /// <param name="RecordToConvert">Variant.</param>
    /// <returns>Return variable ReturnValue of type XmlDocument.</returns>
    procedure ToXml(RecordToConvert: Variant) ReturnValue: XmlDocument
    begin
        exit(ToXml(RecordToConvert, false));
    end;

    /// <summary>
    /// ToDelimiter.
    /// </summary>
    /// <param name="RecordToConvert">Variant.</param>
    /// <param name="Delimiter">Text[1].</param>
    /// <param name="UseSystemFields">Boolean.</param>
    /// <returns>Return value of type Text.</returns>
    procedure ToDelimiter(RecordToConvert: Variant; Delimiter: Text[1]; UseSystemFields: Boolean): Text
    var
        Fields: Record Field;
        RecRef: RecordRef;
        WrongTypeErr: Label 'RecordToConvert must be type Recored.';
    begin
        if not RecordToConvert.IsRecord() then
            Error(WrongTypeErr);

        RecRef.GetTable(RecordToConvert);
        if not GetFields(RecRef.Number(), Fields, UseSystemFields) then
            exit;

        exit(ProcessToDelimiter(RecRef, Fields, Delimiter));
    end;

    /// <summary>
    /// ToDelimiter.
    /// </summary>
    /// <param name="RecordToConvert">Variant.</param>
    /// <param name="Delimiter">Text[1].</param>
    /// <returns>Return variable ReturnValue of type Text.</returns>
    procedure ToDelimiter(RecordToConvert: Variant; Delimiter: Text[1]) ReturnValue: Text
    begin
        exit(ToDelimiter(RecordToConvert, Delimiter, false));
    end;

    local procedure ProcessToJson(RecRef: RecordRef; var Fields: Record Field; var ReturnValue: JsonObject)
    begin
        repeat
            AddValueForJsonType(RecRef, Fields, ReturnValue);
        until Fields.Next() = 0;
    end;

    local procedure AddValueForJsonType(RecRef: RecordRef; Fields: Record Field; var ReturnValue: JsonObject)
    var
        BooleanValue: Boolean;
        IntegerValue: Integer;
        DecimalValue: Decimal;
        DateValue: Date;
        TimeValue: Time;
        DurationValue: Duration;
        DateTimeValue: DateTime;
    begin
        if Fields.Class = Fields.Class::FlowField then
            RecRef.Field(Fields."No.").CalcField();

        case Fields.Type of
            Fields.Type::Boolean:
                if Evaluate(BooleanValue, Format(RecRef.Field(Fields."No.").Value)) then
                    ReturnValue.Add(GetSafeFieldName(Fields), BooleanValue);
            Fields.Type::Code, Fields.Type::Text:
                ReturnValue.Add(GetSafeFieldName(Fields), Format(RecRef.Field(Fields."No.").Value));
            Fields.Type::Integer:
                if Evaluate(IntegerValue, Format(RecRef.Field(Fields."No.").Value)) then
                    ReturnValue.Add(GetSafeFieldName(Fields), IntegerValue);
            Fields.Type::Decimal:
                if Evaluate(DecimalValue, Format(RecRef.Field(Fields."No.").Value)) then
                    ReturnValue.Add(GetSafeFieldName(Fields), DecimalValue);
            Fields.Type::Date:
                if Evaluate(DateValue, Format(RecRef.Field(Fields."No.").Value)) then
                    ReturnValue.Add(GetSafeFieldName(Fields), DateValue);
            Fields.Type::Time:
                if Evaluate(TimeValue, Format(RecRef.Field(Fields."No.").Value)) then
                    ReturnValue.Add(GetSafeFieldName(Fields), TimeValue);
            Fields.Type::Duration:
                if Evaluate(DurationValue, Format(RecRef.Field(Fields."No.").Value)) then
                    ReturnValue.Add(GetSafeFieldName(Fields), DurationValue);
            Fields.Type::DateTime:
                if Evaluate(DateTimeValue, Format(RecRef.Field(Fields."No.").Value)) then
                    ReturnValue.Add(GetSafeFieldName(Fields), DateTimeValue);
            Fields.Type::Option:
                if Evaluate(IntegerValue, Format(RecRef.Field(Fields."No.").Value)) then
                    ReturnValue.Add(GetSafeFieldName(Fields), IntegerValue);
        end;
    end;

    local procedure ProcessToXml(RecRef: RecordRef; var Fields: Record Field; var ReturnValue: XmlDocument)
    var
        XMlDecl: XmlDeclaration;
        RootElement: XmlElement;
        ElementFld: XmlElement;
        V1Lbl: Label '1.0';
        UTF8Lbl: Label 'utf-8';
        YesLbl: Label 'yes';
    begin
        ReturnValue := XmlDocument.Create();
        XmlDecl := xmlDeclaration.Create(V1Lbl, UTF8Lbl, YesLbl);
        ReturnValue.SetDeclaration(XMlDecl);

        RootElement := XmlElement.Create(Fields.TableName);
        repeat
            ElementFld := XmlElement.Create(GetSafeFieldName(Fields));
            ElementFld.Add(XmlText.Create(Format(RecRef.Field(FIelds."No.").Value)));
            RootElement.Add(ElementFld);
        until Fields.Next() = 0;

        ReturnValue.Add(RootElement);
    end;

    local procedure GetFields(TableNo: Integer; var Fields: Record Field; UseSystemFields: Boolean): Boolean
    var
        CommpanyInfo: Record "Company Information";
    begin
        Fields.SetRange(TableNo, TableNo);
        Fields.SetRange(ObsoleteState, Fields.ObsoleteState::No);
        if not UseSystemFields then
            Fields.SetFilter("No.", '<%1', CommpanyInfo.FieldNo(SystemId));
        exit(Fields.FindSet());
    end;

    local procedure GetSafeFieldName(Fields: Record Field): Text
    var
        SpaceLbl: Label ' ';
        UnderscoreLbl: Label '_';
        DotLbl: Label '.';
        EmptyTxt: Label '';
        BadCharLbl: Label '!"£$%^&*().,?/\|';
        WhereLbl: Label '=';
    begin
        exit(DelChr(Format(Fields.FieldName).Replace(SpaceLbl, UnderscoreLbl).Replace(DotLbl, EmptyTxt), WhereLbl, BadCharLbl));
    end;

    local procedure ProcessToDelimiter(RecRef: RecordRef; var Fields: Record Field; Delimiter: Text[1]): Text
    var
        DelimiterTB: TextBuilder;
    begin
        repeat
            if DelimiterTB.Length() > 0 then
                DelimiterTB.Append(Delimiter);

            DelimiterTB.Append(Format(RecRef.Field(Fields."No.").Value));
        until Fields.Next() = 0;

        exit(DelimiterTB.ToText());
    end;
}
