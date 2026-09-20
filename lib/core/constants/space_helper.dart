/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: space_helper.dart
/// Purpose: Space helper.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

// Date: 6/8/2024
// By: Nada Mohammed
// Last update: 6/8/2024
// Objectives: This file is responsible for providing helper widgets for spacing.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Vertical spacing
SizedBox verticalSpace(double height) {
  return SizedBox(
    height: height.h,
  );
}

// Horizontal spacing
SizedBox horizontalSpace(double width) {
  return SizedBox(
    width: width.w,
  );
}
