library my_payment;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:my_payment/input_formatters.dart';
import 'package:my_payment/my_strings.dart';
import 'package:my_payment/payment_card.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Strings.appName,
      theme: new ThemeData(
        primarySwatch: Colors.red,
      ),
      home: new MyHomePage(title: Strings.appName),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  var _formKey = new GlobalKey<FormState>();
  var numberController = new TextEditingController();
  var _paymentCard = PaymentCard();
  var _autoValidate = false;
  var _card = new PaymentCard();

  @override
  void initState() {
    super.initState();
    _paymentCard.type = CardType.Others;
    numberController.addListener(_getCardTypeFrmNumber);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        backgroundColor: Colors.redAccent,
        //title: new Text('Вместе! Маркет'),
      ),
      body: Column(
        children: [
          new SizedBox(
            height: 17.0,
          ),
          Text(
              'Вместе! Маркет',
            style: TextStyle (fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.redAccent)
          ),
          Container(
            margin: EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 10),
            height: 300,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  )
                ]),
            child: new Form(
              key: _formKey,
              // ignore: deprecated_member_use
              autovalidate: _autoValidate,
              child: new ListView(
                padding: EdgeInsets.all(10),
                children: <Widget>[
                  new SizedBox(
                    height: 10.0,
                  ),
                  new Text(
                    Strings.payment.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 15.0, fontWeight: FontWeight.bold),
                  ),
                  new Text(
                    Strings.num.toUpperCase(),
                    style: const TextStyle(fontSize: 14.0),
                  ),
                  new SizedBox(
                    height: 10.0,
                  ),
                  new Text(
                    Strings.sum.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 15.0, fontWeight: FontWeight.bold),
                  ),
                  new SizedBox(
                    height: 10.0,
                  ),
                  new TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      // ignore: deprecated_member_use
                      FilteringTextInputFormatter.digitsOnly,
                      new LengthLimitingTextInputFormatter(19),
                      new CardNumberInputFormatter()
                    ],
                    controller: numberController,
                    decoration: new InputDecoration(
                      border: const OutlineInputBorder(),
                      filled: true,
                      labelText: 'Номер карты',
                    ),
                    onSaved: (String value) {
                      print('onSaved = $value');
                      print('Num controller has = ${numberController.text}');
                      _paymentCard.number = CardUtils.getCleanedNumber(value);
                    },
                    validator: CardUtils.validateCardNum,
                  ),
                  new SizedBox(
                    height: 30.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      new Expanded(
                        child: new TextFormField(
                          inputFormatters: [
                            // ignore: deprecated_member_use
                            WhitelistingTextInputFormatter.digitsOnly,
                            new LengthLimitingTextInputFormatter(4),
                            new CardMonthInputFormatter()
                          ],
                          decoration: new InputDecoration(
                            border: const OutlineInputBorder(),
                            filled: true,
                            hintText: 'ММ/ГГ',
                            labelText: 'Срок действия',
                          ),
                          validator: CardUtils.validateDate,
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            List<int> expiryDate =
                            CardUtils.getExpiryDate(value);
                            _paymentCard.month = expiryDate[0];
                            _paymentCard.year = expiryDate[1];
                          },
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(
                            left: 10,
                          )),
                      new Expanded(
                        child: new TextFormField(
                          obscureText: true,
                          inputFormatters: [
                            // ignore: deprecated_member_use
                            WhitelistingTextInputFormatter.digitsOnly,
                            new LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: new InputDecoration(
                            border: const OutlineInputBorder(),
                            filled: true,
                            hintText: '3 цифры на обороте ',
                            labelText: 'CVС',
                          ),
                          validator: CardUtils.validateCVV,
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            _paymentCard.cvv = int.parse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  // new SizedBox(
                  //   height: 30.0,
                  // ),
                ],
              ),
            ),
          ),
          new SizedBox(
            height: 20.0,
          ),
          new Container(
            alignment: Alignment.center,
            child: _getPayButton(),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    numberController.removeListener(_getCardTypeFrmNumber);
    numberController.dispose();
    super.dispose();
  }

  void _getCardTypeFrmNumber() {
    String input = CardUtils.getCleanedNumber(numberController.text);
    CardType cardType = CardUtils.getCardTypeFrmNumber(input);
    setState(() {
      this._paymentCard.type = cardType;
    });
  }

  void _validateInputs() {
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      setState(() {
        _autoValidate = true;
      });
      _showInSnackBar('Пожалуйста, исправьте ошибки перед отправкой.');
    } else {
      form.save();
      _showInSnackBar('Карта оплаты действительна');
    }
  }

  // ignore: unused_element
  Widget _getPayButton() {
    if (Platform.isIOS) {
      return new CupertinoButton(
        onPressed: _validateInputs,
        color: CupertinoColors.systemRed,
        child: const Text(
          Strings.pay,
          style: const TextStyle(fontSize: 15.0),
        ),
      );
    } else {
      return new RaisedButton(
        onPressed: _validateInputs,
        color: Colors.grey,
        splashColor: Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(const Radius.circular(5.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 145.0),
        textColor: Colors.white,
        child: new Text(
          Strings.pay.toUpperCase(),
          style: const TextStyle(fontSize: 15.0),
        ),
      );
    }
  }

  void _showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value),
      duration: new Duration(seconds: 3),
    ));
  }
}
