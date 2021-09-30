// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

// Package imports:
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:network_arch/constants.dart';
import 'package:network_arch/models/connectivity_model.dart';
import 'package:network_arch/models/lan_scanner_model.dart';
import 'package:network_arch/models/permissions_model.dart';
import 'package:network_arch/models/toast_notification_model.dart';
import 'package:network_arch/services/utils/enums.dart';
import 'package:network_arch/services/widgets/drawer.dart';
import 'package:network_arch/services/widgets/platform_widget.dart';
import 'package:network_arch/services/widgets/shared_widgets.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    context.read<ToastNotificationModel>().fToast.init(context);

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      final permissions = context.read<PermissionsModel>();

      await permissions.initPrefs();

      Permission.location.isGranted.then((bool isGranted) {
        if (isGranted) {
          permissions.isLocationPermissionGranted = true;
        } else if (!isGranted &&
            (permissions.prefs!
                    .getBool('hasLocationPermissionsBeenRequested') ??
                false)) {
          Future.delayed(
            Duration.zero,
            () {
              Constants.showToast(context.read<ToastNotificationModel>().fToast,
                  Constants.permissionDeniedToast);
            },
          );
        } else {
          Navigator.of(context).pushReplacementNamed('/permissions');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      androidBuilder: _buildAndroid,
      iosBuilder: _buildIOS,
    );
  }

  Scaffold _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
        ),
        iconTheme: Theme.of(context).iconTheme,
        titleTextStyle: Theme.of(context).textTheme.headline6,
      ),
      drawer: const DrawerWidget(),
      body: _buildBody(context),
    );
  }

  CupertinoPageScaffold _buildIOS(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const CupertinoSliverNavigationBar(
            stretch: true,
            border: null,
            largeTitle: Text(
              'Dashboard',
            ),
          )
        ],
        body: _buildBody(context),
      ),
    );
  }

  Padding _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0.0),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder(
                stream: context.read<ConnectivityModel>().getWifiInfoStream,
                initialData: null,
                builder:
                    (context, AsyncSnapshot<SynchronousWifiInfo?> snapshot) {
                  if (snapshot.hasError) {
                    return const ErrorCard(
                      message: Constants.defaultError,
                    );
                  }

                  if (!snapshot.hasData) {
                    return const LoadingCard();
                  } else {
                    final bool isWifiConnected =
                        snapshot.data!.wifiIPv4 != null;

                    if (isWifiConnected) {
                      final model = context.read<LanScannerModel>();

                      model.configure(ip: snapshot.data!.wifiIPv4);
                    }

                    return NetworkCard(
                      isNetworkConnected: isWifiConnected,
                      networkType: NetworkType.wifi,
                      firstLine: snapshot.data!.wifiSSID ?? 'N/A',
                      onPressed: () {
                        // TODO: Implement onTap()

                        Navigator.of(context).pushNamed('/wifi');
                      },
                    );
                  }
                },
              ),
              StreamBuilder(
                stream: context.read<ConnectivityModel>().getCellularInfoStream,
                initialData: null,
                builder:
                    (context, AsyncSnapshot<SynchronousCarrierInfo?> snapshot) {
                  if (snapshot.hasError) {
                    if (snapshot.error is NoSimCardException) {
                      return const ErrorCard(
                        message: Constants.simError,
                      );
                    } else {
                      return const ErrorCard(
                        message: Constants.defaultError,
                      );
                    }
                  }

                  if (!snapshot.hasData) {
                    return const LoadingCard();
                  } else {
                    final bool isCellularConnected =
                        snapshot.data!.carrierName != null;

                    return NetworkCard(
                      isNetworkConnected: isCellularConnected,
                      networkType: NetworkType.cellular,
                      firstLine: snapshot.data!.carrierName ?? 'N/A',
                      onPressed: () {
                        // TODO: Implement onTap()
                      },
                    );
                  }
                },
              ),
              const Divider(
                indent: 15,
                endIndent: 15,
              ),
              ToolCard(
                toolName: 'Ping',
                toolDesc: Constants.pingDesc,
                onPressed: () {
                  Navigator.pushNamed(context, '/tools/ping', arguments: '');
                },
              ),
              // ToolCard(
              //   toolName: 'LAN Scanner',
              //   toolDesc: Constants.lanScannerDesc,
              //   onPressed: () {
              //     Navigator.pushNamed(context, '/tools/lan');
              //   },
              // ),
              ToolCard(
                toolName: 'Wake On LAN',
                toolDesc: Constants.wolDesc,
                onPressed: () {
                  Navigator.pushNamed(context, '/tools/wol');
                },
              ),
              ToolCard(
                toolName: 'IP Geolocation',
                toolDesc: Constants.ipGeoDesc,
                onPressed: () {
                  // TODO: Implement onTap()
                  Navigator.pushNamed(context, '/tools/ip_geo');
                },
              ),
              ToolCard(
                toolName: 'Whois',
                toolDesc: Constants.whoisDesc,
                onPressed: () {
                  // TODO: Implement onTap()

                  Constants.showToast(
                      context.read<ToastNotificationModel>().fToast,
                      Constants.permissionGrantedToast);
                },
              ),
              ToolCard(
                toolName: 'DNS Lookup',
                toolDesc: Constants.dnsDesc,
                onPressed: () {
                  // TODO: Implement onTap()

                  Constants.showToast(
                      context.read<ToastNotificationModel>().fToast,
                      Constants.permissionDeniedToast);
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
