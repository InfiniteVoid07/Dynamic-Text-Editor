class Change<T> {

  final void Function() _execute;
  final T _oldValue;
  final void Function(T oldValue) _undo;

  Change(
    this._oldValue,
    this._execute(),
    this._undo(T oldValue),
  );

  void execute() {
    _execute();
  }
  
  void undo() {
    _undo(_oldValue);
  }

}
