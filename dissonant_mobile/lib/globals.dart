library dissonant_mobile.globals;

import 'package:web_socket_channel/io.dart';

String serverURL = "localhost:3490";
String wsURL = "ws://" + serverURL + "/wsconnect";
String loginURL = "http://" + serverURL + "/api/login";

IOWebSocketChannel channel = null;