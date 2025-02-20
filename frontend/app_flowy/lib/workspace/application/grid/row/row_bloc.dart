import 'dart:collection';
import 'package:app_flowy/workspace/application/grid/cell/cell_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Field;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService _rowService;
  final GridRowCache _rowCache;
  void Function()? _rowListenFn;

  RowBloc({
    required GridRow rowData,
    required GridRowCache rowCache,
  })  : _rowService = RowService(gridId: rowData.gridId, rowId: rowData.rowId),
        _rowCache = rowCache,
        super(RowState.initial(rowData, rowCache.loadGridCells(rowData.rowId))) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {
            await _startListening();
          },
          createRow: (_CreateRow value) {
            _rowService.createRow();
          },
          didReceiveCellDatas: (_DidReceiveCellDatas value) async {
            final fields = value.gridCellMap.values.map((e) => CellSnapshot(e.field)).toList();
            final snapshots = UnmodifiableListView(fields);
            emit(state.copyWith(
              gridCellMap: value.gridCellMap,
              snapshots: snapshots,
              changeReason: value.reason,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_rowListenFn != null) {
      _rowCache.removeRowListener(_rowListenFn!);
    }

    return super.close();
  }

  Future<void> _startListening() async {
    _rowListenFn = _rowCache.addRowListener(
      rowId: state.rowData.rowId,
      onUpdated: (cellDatas, reason) => add(RowEvent.didReceiveCellDatas(cellDatas, reason)),
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class RowEvent with _$RowEvent {
  const factory RowEvent.initial() = _InitialRow;
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.didReceiveCellDatas(GridCellMap gridCellMap, GridRowChangeReason reason) =
      _DidReceiveCellDatas;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required GridRow rowData,
    required GridCellMap gridCellMap,
    required UnmodifiableListView<CellSnapshot> snapshots,
    GridRowChangeReason? changeReason,
  }) = _RowState;

  factory RowState.initial(GridRow rowData, GridCellMap cellDataMap) => RowState(
        rowData: rowData,
        gridCellMap: cellDataMap,
        snapshots: UnmodifiableListView(cellDataMap.values.map((e) => CellSnapshot(e.field)).toList()),
      );
}

class CellSnapshot extends Equatable {
  final Field _field;

  const CellSnapshot(Field field) : _field = field;

  @override
  List<Object?> get props => [
        _field.id,
        _field.fieldType,
        _field.visibility,
      ];
}
