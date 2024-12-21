import 'package:blocknet/app/theme.dart';
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
      style: TextStyle(
        color: AppColors.darkGrey400,
        fontSize: size,
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

class StyledBodyText600 extends StatelessWidget {
  const StyledBodyText600(this.text, {this.size = 14.0, super.key});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.darkGrey600,
        fontSize: size,
        fontWeight: FontWeight.w500,
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
      style: style ?? Theme.of(context).textTheme.titleLarge,
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
