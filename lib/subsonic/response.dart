enum ResponseStatus { ok, failed }

class SubsonicResponse<T> {
  final ResponseStatus status;
  final String version;
  final T data;

  SubsonicResponse(this.status, this.version, this.data);
}
