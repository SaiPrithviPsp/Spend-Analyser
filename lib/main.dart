import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:sms/sms.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Test App",
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class Payment {
  double amount;
  DateTime date;
  String payee;

  Payment(this.amount, this.date, this.payee);
}

class Category {
  String name;
  double total;
  List<Payment> payments;

  Category(this.name, this.total, this.payments);
}

class _HomePageState extends State<HomePage> {
  SmsQuery query = new SmsQuery();
  List<SmsMessage>? allmessages;

  var payees = {
    'swiggy': 'Food',
    'zomato': 'Food',
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'goibibo': 'Travel',
    'irctc': 'Travel',
    'gpay': 'Others',
    'inox': 'Others',
  };
  var result = {
    'Food': Category('Food', 0, []),
    'Shopping': Category('Shopping', 0, []),
    'Travel': Category('Travel', 0, []),
    'Others': Category('Others', 0, [])
  };
  var finalResult = {};

  @override
  void initState() {
    getAllMessages();
    super.initState();
  }

  double getAmount(String message) {
    RegExp regExp = RegExp(
      r"INR [0-9]+\.?[0-9]*",
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.firstMatch(message)?.group(0) == null) {
      return 0.0;
    } else {
      String? x = regExp.firstMatch(message)?.group(0);
      // print(x!.substring(4));
      double d = double.parse(x!.substring(4));
      return d;
    }
  }

  void parseMessage(SmsMessage message) {
    String messageText = message.body;
    String category = '';
    bool flag = true;
    payees.keys.forEach((payee) {
      double amount = getAmount(messageText);
      Payment payment = Payment(amount, message.date, payee);
      if (messageText.toLowerCase().contains(payee.toLowerCase()) && amount != 0.0) {
        category = payees[payee]!;
        result[category]?.payments.add(payment);
        result[category]?.total += payment.amount;
        flag = false;
      }
    });
  }


  void getAllMessages() {
    Future.delayed(Duration.zero, () async {

      // You can can also directly ask the permission about its status.
      if (await Permission.sms.request().isGranted) {
        // The OS restricts access, for example because of parental controls.
        List<SmsMessage> messages =
        await query.querySms( //querySms is from sms package
            kinds: [SmsQueryKind.Inbox]);
        List<SmsMessage> _messages = messages.where((i) =>
            i.body.toLowerCase().contains("debit")).toList();
        print("SMS data retreived");
        print(messages.length);
        print(_messages.length);
        allmessages = _messages;
        allmessages!.forEach((message) {
          parseMessage(message);
        });
        print(result);

        setState(() {
          //update UI
          finalResult = result;
          print(finalResult);
        });
      }
    });
  }

  Map<String, double> getDataMap(Map<String, Category> result) {
    Map<String, double> dataMap = {};
    result.entries.forEach((element) {
      Category category = element.value;
      List categorywisePayments =category.payments;
      categorywisePayments.forEach((element2) {
        Payment payment = element2 as Payment;
        dataMap[element.key] = (dataMap[element.key] ?? 0) + payment.amount;
      });
    });



    return dataMap;
  }

  List<TableRow> getTableData(List<Payment> listData){
    List<TableRow> tableData = [];

    listData.forEach((payment) {
      DateFormat formatter = DateFormat('dd-MM-yyyy');
      String formatted = formatter.format(payment.date);
      tableData.add( TableRow( children: [
                    Column(children:[Text(payment.payee)], crossAxisAlignment: CrossAxisAlignment.start),
                    Column(children:[Text(payment.amount.toString())], crossAxisAlignment: CrossAxisAlignment.start),
                    Column(children:[Text(formatted)], crossAxisAlignment: CrossAxisAlignment.start)
                  ])
      );
    });

    return tableData;

  }

  List<ExpansionTile> getListData(Map<String, Category> result) {
    List<ExpansionTile> tiles = [];

    result.entries.forEach((entry) {
      List<Payment> listData = [];
      Category category = entry.value;
      List categorywisePayments = category.payments;
      categorywisePayments.forEach((element) {
        Payment payment = element as Payment;
        listData.add(payment
            );
      });
      List<TableRow> tableData = getTableData(listData);
      ExpansionTile tile = ExpansionTile(
        title: Text(entry.key + ": " +category.total.toString()),
        subtitle: Text( categorywisePayments.length.toString() + " transaction(s)"),
        children: [
                  Table(
                    defaultColumnWidth: FixedColumnWidth(120.0),
                    border: TableBorder.all(
                    color: Colors.black,
                    style: BorderStyle.none,
                    width: 2),
                    children: tableData
                  )
                ]
      ,
        expandedAlignment: Alignment.centerLeft,
        tilePadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
        childrenPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),

      );
      tiles.add(tile);
    });

    return tiles;
  }

  Text getTotalAmountSpent(Map<String, Category> result){
    double total = 0;
    result.forEach((key, value) {
      Category category = value as Category;
      total += category.total;
    });
    return Text("Total Expenditure: " + total.toString(), style: TextStyle(fontWeight: FontWeight.bold), textScaleFactor: 1.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Spend Analyser"),
          backgroundColor: Colors.indigoAccent,
        ),
        body: ListView(
            children: finalResult.isEmpty
                ? [const Center(child: CircularProgressIndicator())]
                : [
                    Container(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child:
                            Column(
                              children:[
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0.0,0.0, 0.0, 10.0),
                                  child: Text("Summary", style: TextStyle(fontWeight: FontWeight.bold), textScaleFactor: 1.3)
                                )
                                ,
                                PieChart(
                                  dataMap:
                                      getDataMap(finalResult as Map<String, Category>),
                                  chartValuesOptions: const ChartValuesOptions(
                                    showChartValueBackground: true,
                                    showChartValues: true,
                                    showChartValuesInPercentage: true,
                                    showChartValuesOutside: true,
                                    decimalPlaces: 1,
                                  ),
                                  chartRadius:
                                      MediaQuery.of(context).size.width / 1.8,
                                  legendOptions: const LegendOptions(
                                    showLegendsInRow: false,
                                    legendPosition: LegendPosition.right,
                                    showLegends: true,
                                    legendShape: BoxShape.circle,
                                    legendTextStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  chartType: ChartType.ring,
                                )],
                              crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        padding: EdgeInsets.all(5.0),
                    ),
                    Container(
                        child: Card(
                          child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                  children:
                                  List.from([getTotalAmountSpent(finalResult as Map<String, Category>)])..addAll(getListData(finalResult as Map<String, Category>)),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(5.0),
                    )
                  ]),
            backgroundColor: const Color.fromARGB(255, 230, 230, 230),
            );
  }
}
