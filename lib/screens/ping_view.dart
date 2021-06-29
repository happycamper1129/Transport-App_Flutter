// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:dart_ping/dart_ping.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:network_arch/models/ping_model.dart';
import 'package:network_arch/utils/keyboard_hider.dart';
import 'package:network_arch/widgets/shared_widgets.dart';

class PingView extends StatefulWidget {
  PingView({Key? key}) : super(key: key);

  @override
  _PingViewState createState() => _PingViewState();
}

class _PingViewState extends State<PingView> {
  final targetHostController = TextEditingController();
  IconData pingButtonIcon = FontAwesomeIcons.play;
  Color pingButtonColor = Colors.green;

  @override
  void dispose() {
    targetHostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PingModel pingModel = Provider.of<PingModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ping",
        ),
        iconTheme: Theme.of(context).iconTheme,
        textTheme: Theme.of(context).textTheme,
      ),
      body: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetHostController,
                      autocorrect: false,
                      enabled: !pingModel.isPingingStarted,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        labelText: "IP address",
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: IconButton(
                      splashRadius: 25.0,
                      icon: FaIcon(pingButtonIcon, color: pingButtonColor),
                      onPressed: () {
                        if (pingButtonIcon == FontAwesomeIcons.play) {
                          setState(() {
                            pingButtonIcon = FontAwesomeIcons.times;
                            pingButtonColor = Colors.red;
                          });
                          pingModel.clearData();
                          pingModel.setHost = targetHostController.text;
                          pingModel.isPingingStarted = true;
                        } else {
                          setState(() {
                            pingButtonIcon = FontAwesomeIcons.play;
                            pingButtonColor = Colors.green;
                          });
                          pingModel.stopStream();
                          pingModel.isPingingStarted = false;
                        }

                        targetHostController.clear();
                        hideKeyboard(context);
                      },
                    ),
                  )
                ],
              ),
            ),
            Consumer<PingModel>(
              builder: (context, model, child) {
                if (model.isPingingStarted) {
                  return StreamBuilder(
                    stream: pingModel.getStream(),
                    initialData: null,
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.hasError) {
                        print(snapshot.error);
                      }

                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      } else {
                        model.pingData.add(snapshot.data);

                        return buildPingListView(model);
                      }
                    },
                  );
                } else {
                  return buildPingListView(model);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Padding buildPingListView(PingModel model) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: model.pingData.length,
        itemBuilder: (context, index) {
          PingData currData = model.pingData[index]!;

          if (currData.error != null) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: ListTile(
                leading: StatusCard(
                  color: CupertinoColors.systemRed,
                  text: "Offline",
                ),
                title: Text("N/A"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Seq. position: " +
                        currData.response!.seq.toString() +
                        " "),
                    Text("TTL: N/A"),
                  ],
                ),
                trailing: Text(model.getErrorDesc(currData.error!.error)),
              ),
            );
          }

          if (currData.response != null) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: ListTile(
                leading: StatusCard(
                  color: CupertinoColors.systemGreen,
                  text: "Online",
                ),
                title: Text(currData.response!.ip!),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Seq. pos: " + currData.response!.seq.toString() + " "),
                    Text("TTL: " + currData.response!.ttl.toString())
                  ],
                ),
                trailing: Text(
                  currData.response!.time!.inMilliseconds.toString() + " ms",
                ),
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
