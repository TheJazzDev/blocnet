import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class StyledBodyText extends StatelessWidget {
  const StyledBodyText(this.text, {this.applyOverflow = false, super.key});

  final String text;
  final bool applyOverflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall,
      maxLines: applyOverflow ? 3 : null,
      overflow: applyOverflow ? TextOverflow.ellipsis : null,
    );
  }
}

class StyledBodyText400 extends StatelessWidget {
  const StyledBodyText400(this.text, {this.size = 14.0, super.key});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.custom(
        size: size,
        weight: FontWeight.w400,
        color: AppColors.darkGrey400,
      ),
    );
  }
}

class StyledBodyText500 extends StatelessWidget {
  const StyledBodyText500(this.text, {this.size = 14.0, super.key});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.custom(
        size: size,
        weight: FontWeight.w400,
        color: AppColors.darkGrey500,
      ),
    );
  }
}

class StyledBodyText600 extends StatelessWidget {
  const StyledBodyText600(
    this.text, {
    this.size = 14.0,
    this.fontWeight = FontWeight.w500,
    this.textAlign = TextAlign.left,
    super.key,
  });

  final String text;
  final double size;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: AppTypography.custom(
        size: size,
        weight: fontWeight,
        color: AppColors.darkGrey600,
      ),
    );
  }
}

class StyledBodyText700 extends StatelessWidget {
  const StyledBodyText700(this.text, {this.size, super.key});

  final String text;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.custom(
        size: size ?? 14.0,
        weight: FontWeight.w500,
        color: AppColors.darkGrey700,
      ),
    );
  }
}

class StyledHeading extends StatelessWidget {
  const StyledHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineMedium);
  }
}

class StyledPostProjectTitle extends StatelessWidget {
  const StyledPostProjectTitle(
    this.text, {
    super.key,
    this.style,
    this.applyOverflow = false,
  });

  final String text;
  final TextStyle? style;
  final bool applyOverflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.titleSmall,
      maxLines: applyOverflow ? 1 : null,
      overflow: applyOverflow ? TextOverflow.ellipsis : null,
    );
  }
}

class StyledTitleSmall extends StatelessWidget {
  const StyledTitleSmall(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class StyledTitleMedium extends StatelessWidget {
  const StyledTitleMedium(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class StyledTitleLarge extends StatelessWidget {
  const StyledTitleLarge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

class StyledLabelLarge extends StatelessWidget {
  const StyledLabelLarge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}
