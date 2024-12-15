import 'package:blocknet/app/app_theme.dart';
import 'package:flutter/material.dart';

class StyledBodyText extends StatelessWidget {
  const StyledBodyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class StyledBodyText400 extends StatelessWidget {
  const StyledBodyText400(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.darkGrey400,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: 'Geist',
      ),
    );
  }
}

class StyledBodyText500 extends StatelessWidget {
  const StyledBodyText500(
    this.text, {
    this.size = 14.0,
    super.key,
  });

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.darkGrey500,
        fontSize: size,
        fontWeight: FontWeight.w400,
        fontFamily: 'Geist',
      ),
    );
  }
}

class StyledHeading extends StatelessWidget {
  const StyledHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class StyledHeading2 extends StatelessWidget {
  const StyledHeading2(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.titleLarge,
    );
  }
}

class StyledTitleSmall extends StatelessWidget {
  const StyledTitleSmall(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class StyledTitleMedium extends StatelessWidget {
  const StyledTitleMedium(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class StyledTitleLarge extends StatelessWidget {
  const StyledTitleLarge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class StyledLabelLarge extends StatelessWidget {
  const StyledLabelLarge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}
