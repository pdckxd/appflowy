import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/number_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_switcher.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide NumberFormat;
import 'package:app_flowy/generated/locale_keys.g.dart';

class NumberTypeOptionBuilder extends TypeOptionBuilder {
  final NumberTypeOptionWidget _widget;

  NumberTypeOptionBuilder(
    TypeOptionData typeOptionData,
    TypeOptionOverlayDelegate overlayDelegate,
    TypeOptionDataDelegate dataDelegate,
  ) : _widget = NumberTypeOptionWidget(
          typeOption: NumberTypeOption.fromBuffer(typeOptionData),
          dataDelegate: dataDelegate,
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? get customWidget => _widget;
}

class NumberTypeOptionWidget extends TypeOptionWidget {
  final TypeOptionDataDelegate dataDelegate;
  final TypeOptionOverlayDelegate overlayDelegate;
  final NumberTypeOption typeOption;
  const NumberTypeOptionWidget(
      {required this.typeOption, required this.dataDelegate, required this.overlayDelegate, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider(
      create: (context) => getIt<NumberTypeOptionBloc>(param1: typeOption),
      child: SizedBox(
        height: GridSize.typeOptionItemHeight,
        child: BlocConsumer<NumberTypeOptionBloc, NumberTypeOptionState>(
          listener: (context, state) => dataDelegate.didUpdateTypeOptionData(state.typeOption.writeToBuffer()),
          builder: (context, state) {
            return FlowyButton(
              text: FlowyText.medium(LocaleKeys.grid_field_numberFormat.tr(), fontSize: 12),
              padding: GridSize.typeOptionContentInsets,
              hoverColor: theme.hover,
              onTap: () {
                final list = NumberFormatList(onSelected: (format) {
                  context.read<NumberTypeOptionBloc>().add(NumberTypeOptionEvent.didSelectFormat(format));
                });
                overlayDelegate.showOverlay(context, list);
              },
              rightIcon: svgWidget("grid/more", color: theme.iconColor),
            );
          },
        ),
      ),
    );
  }
}

typedef _SelectNumberFormatCallback = Function(NumberFormat format);

class NumberFormatList extends StatelessWidget {
  final _SelectNumberFormatCallback onSelected;
  const NumberFormatList({required this.onSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = NumberFormat.values.map((format) {
      return NumberFormatCell(
          format: format,
          onSelected: (format) {
            onSelected(format);
            FlowyOverlay.of(context).remove(NumberFormatList.identifier());
          });
    }).toList();

    return SizedBox(
      width: 120,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: cells.length,
        itemBuilder: (BuildContext context, int index) {
          return cells[index];
        },
      ),
    );
  }

  static String identifier() {
    return (NumberFormatList).toString();
  }
}

class NumberFormatCell extends StatelessWidget {
  final NumberFormat format;
  final Function(NumberFormat format) onSelected;
  const NumberFormatCell({required this.format, required this.onSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(format.title(), fontSize: 12),
        hoverColor: theme.hover,
        onTap: () => onSelected(format),
        leftIcon: svgWidget(format.iconName(), color: theme.iconColor),
      ),
    );
  }
}

extension NumberFormatExtension on NumberFormat {
  String title() {
    switch (this) {
      case NumberFormat.CNY:
        return "Yen";
      case NumberFormat.EUR:
        return "Euro";
      case NumberFormat.Number:
        return "Numbers";
      case NumberFormat.USD:
        return "US Dollar";
      default:
        throw UnimplementedError;
    }
  }

  String iconName() {
    switch (this) {
      case NumberFormat.CNY:
        return "grid/field/yen";
      case NumberFormat.EUR:
        return "grid/field/euro";
      case NumberFormat.Number:
        return "grid/field/numbers";
      case NumberFormat.USD:
        return "grid/field/us_dollar";
      default:
        throw UnimplementedError;
    }
  }
}
