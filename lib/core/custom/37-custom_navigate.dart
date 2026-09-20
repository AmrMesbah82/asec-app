/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_navigate.dart
/// Purpose: Widget used by the feature's screens.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/material.dart';

void navigateTo(context, widget) => Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  ),
);

/// Same transition as [navigateTo], but returns the route's Future so the
/// caller can await the pop and refresh itself.
///
/// [navigateTo] returns void, so a list screen that pushes a detail screen has
/// no way to know when the user comes back — it keeps showing whatever it
/// fetched in initState. Use this when the pushed screen can change the data
/// behind the caller (approve / reject / cancel a request, for example).
Future<T?> navigateToAsync<T>(BuildContext context, Widget widget) =>
    Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

//=======================================================================================================================================================

void navigateAndFinish(context, widget) => Navigator.pushAndRemoveUntil(
    context, MaterialPageRoute(builder: (context) => widget), (route) => false);

//=======================================================================================================================================================