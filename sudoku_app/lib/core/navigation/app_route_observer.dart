import 'package:flutter/material.dart';

/// Shared route observer for the app. Used so Home (and others) can react
/// when returning to the screen (e.g. refresh "Continue" after leaving a game).
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
