/*
 * Package : Wilt
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2013
 * Copyright :  S.Hamblett@OSCF
 *
 *
 */

part of wilt;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: public_member_api_docs

/// The Wilt client.
/// * The Wilt class provides core functionality for interacting with
/// CouchDB databases from both the browser and the server.
class Wilt {
  /// Please use the wilt_browser_client or wilt_server_client import files to
  /// instantiate a Wilt object for use in either the browser or
  /// server environment.
  /// You can do this here but you must supply either a browser or
  /// server HTTP adapter
  /// to use.
  Wilt(this._host, this._port, this._scheme, this.httpAdapter,
      [this._clientCompletion]) {
    if ((host == null) || (port == null) || (scheme == null)) {
      throw WiltException(WiltException.badConstParams);
    }

    if (httpAdapter == null) {
      throw WiltException(WiltException.badConstNoAdapter);
    }
  }

  /// URL constant for CouchDB SESSION function
  static const String session = '/_session';

  /// URL constant for CouchDB STATS function
  static const String stats = '/_stats';

  /// URL constant for CouchDB ALLDBS function
  static const String alldbs = '/_all_dbs';

  /// URL constant for CouchDB ALLDOCS function
  static const String alldocs = '/_all_docs';

  /// URL constant for CouchDB BULKDOCS function
  static const String bulkdocs = '/_bulk_docs';

  /// URL constant for CouchDB UUID function
  static const String uuids = '/_uuids';

  /// Etag header
  static const String etag = 'etag';

  /// AUTH_BASIC denotes Basic HTTP authentication.
  /// If login is called AUTH_BASIC is set, otherwise it defaults to AUTH_NONE
  static const String authBasic = 'basic';

  /// AUTH_BEARER denotes OAuth Token HTTP authentication.
  /// If loginWithToken is called AUTH_BEARER is set,
  /// otherwise it defaults to AUTH_NONE
  static const String authBearer = 'bearer';

  /// No authentication
  static const String authNone = 'none';

  /// Operation types and method definitions
  static const String gett = 'GET_GET';
  static const String headd = 'HEAD_HEAD';
  static const String postt = 'POST_POST';
  static const String putt = 'PUT_PUT';
  static const String deletee = 'DELETE_DELETE';
  static const String copy = 'COPY_COPY';
  static const String getDocumentt = 'GET_DOCUMENT';
  static const String deleteDocumentt = 'DELETE_DOCUMENT';
  static const String putDocumentt = 'PUT_DOCUMENT';
  static const String postDocumentt = 'POST_DOCUMENT';
  static const String postDocumentStringg = 'POST_DOCUMENTSTRING';
  static const String copyDocumentt = 'COPY_DOCUMENT';
  static const String getAllDocss = 'GET_ALLDOCS';
  static const String bulkk = 'POST_BULK';
  static const String bulkStringg = 'POST_BULKSTRING';
  static const String createDatabasee = 'PUT_DATABASE';
  static const String deleteDatabasee = 'DELETE_DATABASE';
  static const String databaseInfo = 'GET_DATABASEINFO';
  static const String getSessionn = 'GET_SESSION';
  static const String getStatss = 'GET_STATS';
  static const String getAllDbss = 'GET_ALLDBS';
  static const String createAttachmentt = 'PUT_CREATEATTACH';
  static const String updateAttachmentt = 'PUT_UPDATEATTACH';
  static const String deleteAttachmentt = 'DELETE_ATTACH';
  static const String getAttachmentt = 'GET_ATTACH';
  static const String generateIdss = 'GET_IDS';

  /// Database name
  String db;

  /// Change notification database name
  String changeNotificationDbName;

  /// Host name
  final String _host;

  String get host => _host;

  /// Port number
  final String _port;

  String get port => _port;

  /// HTTP scheme
  final String _scheme;

  String get scheme => _scheme;

  /// HTTP Adapter
  WiltHTTPAdapter httpAdapter;

  /// Change notification
  _WiltChangeNotification _changeNotifier;

  /// Change notification event stream
  /// This is a broadcast stream so can support more than one listener.
  Stream<WiltChangeNotificationEvent> get changeNotification =>
      _changeNotifier.changeNotification.stream;

  /// Change notification paused state
  bool get changeNotificationsPaused => _changeNotifier.paused;

  /// Completion function
  dynamic _clientCompletion;

  /// Completion callback
  // ignore: avoid_setters_without_getters
  set resultCompletion(final Object completion) {
    _clientCompletion = completion;
  }

  /// Response getter for completion callbacks
  jsonobject.JsonObjectLite<dynamic> _completionResponse;

  jsonobject.JsonObjectLite<dynamic> get completionResponse =>
      _completionResponse;

  /// Authentication, user name
  String _user;

  /// Authentication, user password
  String _password;

  /// OAuth token for authorization. either user, password will be set or this.
  String _token;

  /// Authentication, type
  String authenticationType = authNone;

  /// The internal HTTP request method. This wraps the
  /// HTTP adapter class.
  Future<dynamic> _httpRequest(String method, String url,
      {String data, Map<String, String> headers}) {
    // Build the request for the HttpAdapter
    final Map<String, String> wiltHeaders = <String, String>{};
    wiltHeaders['Accept'] = 'application/json';
    if (headers != null) {
      wiltHeaders.addAll(headers);
    }

    // Build the URL
    final String wiltUrl = '$scheme$host:$port$url';

    // Check for authentication
    if (_user != null) {
      switch (authenticationType) {
        case authBasic:
          final String authStringToEncode = '$_user:$_password';
          final String encodedAuthString =
              const Base64Encoder().convert(authStringToEncode.codeUnits);
          final String authString = 'Basic $encodedAuthString';
          wiltHeaders['Authorization'] = authString;
          break;

        case authNone:
          break;
      }
    }

    // Execute the request
    final Future<dynamic> completion =
        httpAdapter.httpRequest(method, wiltUrl, data, wiltHeaders)
          ..then((dynamic jsonResponse) {
            if (_clientCompletion != null) {
              _completionResponse = jsonResponse;
              _clientCompletion();
            }
          });

    return completion;
  }

  /// Takes a URL and key/value pair for a URL parameter and adds this
  /// to the query parameters of the URL.
  String _setURLParameter(String url, String key, String value) {
    final Uri originalUrl = Uri.parse(url);
    final Map<String, String> queryParams = originalUrl.queryParameters;
    final Map<String, String> newQueryParams =
        Map<String, String>.from(queryParams);
    newQueryParams[key] = value;

    final Uri newUrl = Uri(
        scheme: originalUrl.scheme,
        userInfo: originalUrl.userInfo,
        host: originalUrl.host,
        port: originalUrl.port,
        path: originalUrl.path,
        queryParameters: newQueryParams);

    final String returnUrl = newUrl.toString();
    return returnUrl; // Private
  }

  /// Conditions the URL for use by Wilt and checks for
  /// a valid database by default.
  String _conditionUrl(String url) {
    if (db == null) {
      return WiltException.noDatabaseSpecified;
    }
    if (url == null) {
      return '/';
    }
    String urlRet = url;
    // The first char of the URL should be a slash.
    if (!url.startsWith('/')) {
      urlRet = '/$urlRet';
    }
    if (db != null) {
      urlRet = '/$db$urlRet';
    }
    return urlRet;
  }

  /// Raise an exception from a future API call.
  /// If we are using completion throw an exception as normal.
  Future<WiltException> _raiseException(String name) {
    if (_clientCompletion == null) {
      return Future<WiltException>.error(WiltException(name));
    } else {
      throw WiltException(name);
    }
  }

  /// Basic method where only a URL and a method is passed.
  /// Wilt applies no checks to this URL nor does it add the
  /// database, the format of this is entirely up to the user.
  ///
  /// This can be used for CouchDb functions that are not directly
  /// supported by Wilt, e.g views, attachments and design documents.
  Future<dynamic> httpRequest(String url, {String method = 'GET'}) =>
      _httpRequest(method, url);

  /// Performs an HTTP GET operation, the URL is conditioned and
  /// the current database added.
  Future<dynamic> get(String url) {
    final String url1 = _conditionUrl(url);
    if (url1 == WiltException.noDatabaseSpecified) {
      return _raiseException(WiltException.noDatabaseSpecified);
    }

    // Perform the get
    return _httpRequest('GET', url1);
  }

  /// Performs a HTTP HEAD operation, the URL is conditioned and
  /// the current database added.
  Future<dynamic> head(String url) {
    final String url1 = _conditionUrl(url);
    if (url1 == WiltException.noDatabaseSpecified) {
      return _raiseException(WiltException.noDatabaseSpecified);
    }

    // Perform the head
    return _httpRequest(headd, url1);
  }

  /// Performs a HTTP POST operation,, the URL is conditioned and
  /// the current database added.
  Future<dynamic> post(String url, String data, [Map<String, String> headers]) {
    final String url1 = _conditionUrl(url);
    if (url1 == WiltException.noDatabaseSpecified) {
      return _raiseException(WiltException.noDatabaseSpecified);
    }

    // Perform the post
    return _httpRequest('POST', url1, data: data, headers: headers);
  }

  /// Performs a HTTP PUT operation,, the URL is conditioned and
  /// the current database added.
  Future<dynamic> put(String url, String data, [Map<String, String> headers]) {
    final String url1 = _conditionUrl(url);
    if (url1 == WiltException.noDatabaseSpecified) {
      return _raiseException(WiltException.noDatabaseSpecified);
    }

    // Perform the put
    return _httpRequest('PUT', url1, data: data, headers: headers);
  }

  /// Performs a HTTP DELETE operation,, the URL is conditioned and
  /// the current database added.
  Future<dynamic> delete(String url) {
    final String url1 = _conditionUrl(url);
    if (url1 == WiltException.noDatabaseSpecified) {
      return _raiseException(WiltException.noDatabaseSpecified);
    }

    // Perform the delete
    return _httpRequest('DELETE', url1);
  }

  /// Performs an HTTP GET operation for the supplied document id and
  /// optional revision. If withAttachments is set the the body of
  /// any attachments are also supplied, note this could make this
  /// a large transfer.
  Future<dynamic> getDocument(String id,
      // ignore: avoid_positional_boolean_parameters
      [String rev,
      // ignore: avoid_positional_boolean_parameters
      bool withAttachments = false]) {
    if (id == null) {
      return _raiseException(WiltException.getDocNoId);
    }

    String url = id;
    if (rev != null) {
      url = _setURLParameter(url, 'rev', rev);
    }

    if (withAttachments) {
      url = _setURLParameter(url, 'attachments', 'true');
    }

    url = _conditionUrl(url);
    return _httpRequest('GET_DOCUMENT', url);
  }

  /// Gets a documents current revision, returns null if
  /// the document does not exist.
  Future<dynamic> getDocumentRevision(String id) {
    if (id == null) {
      return _raiseException(WiltException.getDocRevNoId);
    }

    final Completer<dynamic> completer = Completer<dynamic>();
    head(id).then((dynamic res) {
      final dynamic headers = WiltUserUtils.mapToJson(res.allResponseHeaders);
      if (headers != null) {
        final dynamic jsonHeaders =
            jsonobject.JsonObjectLite<dynamic>.fromJsonString(headers);
        if (jsonHeaders.containsKey(Wilt.etag)) {
          String ver = jsonHeaders[Wilt.etag];
          ver = ver.substring(1, ver.length - 1);
          completer.complete(ver);
        } else {
          completer.complete(null);
        }
      } else {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// DELETE's the specified document. Must have a revision.
  /// If preserve is set to true the whole document is preserved
  /// and marked as deleted otherwise only a stub document is
  /// kept. Default is to not preserve.
  // ignore: avoid_positional_boolean_parameters
  Future<dynamic> deleteDocument(String id, String rev,
      // ignore: avoid_positional_boolean_parameters
      [bool preserve = false]) {
    if ((id == null) || (rev == null)) {
      return _raiseException(WiltException.deleteDocNoIdRev);
    }
    final Completer<dynamic> completer = Completer<dynamic>();

    // Check the preserve flag
    if (preserve) {
      getDocument(id).then((dynamic res) {
        if (res != null) {
          dynamic resp = res.jsonCouchResponse;
          resp = WiltUserUtils.addDocumentDeleteJo(resp);
          putDocument(id, resp).then(completer.complete);
        } else {
          completer.complete(null);
        }
      });
      return completer.future;
    } else {
      String url = id;
      url = _setURLParameter(url, 'rev', rev);
      url = _conditionUrl(url);
      return _httpRequest('DELETE_DOCUMENT', url);
    }
  }

  /// PUT's to the specified  document.
  ///
  /// For an update the revision must be specified, this can be in the
  /// document body as a _rev parameter or specified in the call in which
  /// case this will be added to the document body.
  Future<dynamic> putDocument(
      String id, jsonobject.JsonObjectLite<dynamic> document,
      [String rev]) {
    if ((id == null) || (document == null)) {
      return _raiseException(WiltException.putDocNoIdBody);
    }

    // Check for a revision
    String jsonData;

    try {
      if (rev != null) {
        jsonData = WiltUserUtils.addDocumentRev(document, rev);
      } else {
        jsonData = json.encode(document);
      }
    } on Exception {
      return _raiseException(WiltException.putDocCantStringify);
    }

    final String url = _conditionUrl(id);
    return _httpRequest(putDocumentt, url, data: jsonData);
  }

  /// PUT's to the specified  document where the document is supplied as
  /// a json string. Must be used if '_id' and or '_rev' are needed.
  Future<dynamic> putDocumentString(String id, String document, [String rev]) {
    if ((id == null) || (document == null)) {
      return _raiseException(WiltException.putDocStringNoIdBody);
    }

    // Check for a revision
    String id1 = id;
    if (rev != null) {
      id1 = '$id1?rev=$rev';
    }
    final String url = _conditionUrl(id1);
    return _httpRequest(putDocumentt, url, data: document);
  }

  /// POST's the specified document.
  /// An optional path to the document can be specified.
  Future<dynamic> postDocument(jsonobject.JsonObjectLite<dynamic> document,
      {String path}) {
    if (document == null) {
      return _raiseException(WiltException.postDocNoBody);
    }

    String url = '';
    if (path != null) {
      url = '$url/$path';
    }

    // Set the content type for a post
    final Map<String, String> headers = <String, String>{};
    headers['Content-Type'] = 'application/json';

    String jsonData;
    try {
      jsonData = json.encode(document);
    } on Exception {
      return _raiseException(WiltException.postDocCantStringify);
    }

    url = _conditionUrl(url);
    return _httpRequest(postDocumentt, url, data: jsonData, headers: headers);
  }

  /// POST's to the specified  document where the document is supplied as
  /// a json string. Must be used if '_id' and or '_rev' are needed.
  Future<dynamic> postDocumentString(String document, {String path}) {
    if (document == null) {
      return _raiseException(WiltException.postDocStringNoBody);
    }

    String url = '';
    if (path != null) {
      url = '$url/$path';
    }

    // Set the content type for a post
    final Map<String, String> headers = <String, String>{};
    headers['Content-Type'] = 'application/json';

    url = _conditionUrl(url);
    return _httpRequest('POST_DOCUMENT_STRING', url,
        data: document, headers: headers);
  }

  /// Copies the source document to the destination document with an
  /// optional revision. NOTE this method uses the CouchDB COPY method which is
  /// not standard HTTP.
  Future<dynamic> copyDocument(String sourceId, String destinationId,
      [String rev]) {
    if (sourceId == null) {
      return _raiseException(WiltException.copyDocNoSrcId);
    }

    if (destinationId == null) {
      return _raiseException(WiltException.copyDocNoDestId);
    }

    String url = sourceId;

    // Create the special COPY header
    final Map<String, String> headers = <String, String>{};
    String destination = destinationId;
    if (rev != null) {
      destination = '$destinationId?rev=$rev';
    }
    headers['Destination'] = destination;

    url = _conditionUrl(url);
    return _httpRequest('COPY_DOCUMENT', url, headers: headers);
  }

  /// Get all documents.
  /// The parameters should be self explanatory and are addative.
  /// Refer to the CouchDb documentation for further explanation.
  Future<dynamic> getAllDocs(
      {bool includeDocs = false,
      int limit,
      String startKey,
      String endKey,
      List<String> keys,
      bool descending = false}) {
    // Validate the parameters
    if ((limit != null) && (limit < 0)) {
      return _raiseException(WiltException.getAllDocsLimit);
    }

    String url = alldocs;

    // Check the parameters and build the URL as needed
    if (includeDocs) {
      url = _setURLParameter(url, 'include_docs', 'true');
    }

    if (limit != null) {
      url = _setURLParameter(url, 'limit', limit.toString());
    }

    if (startKey != null) {
      final String jsonStartkey = '"$startKey"';
      url = _setURLParameter(url, 'startkey', jsonStartkey);
    }

    if (endKey != null) {
      final String jsonEndkey = '"$endKey"';
      url = _setURLParameter(url, 'endkey', jsonEndkey);
    }

    if (descending) {
      url = _setURLParameter(url, 'descending', descending.toString());
    }

    if (keys != null) {
      final String keyString = json.encode(keys);
      url = _setURLParameter(url, 'keys', keyString);
    }

    url = _conditionUrl(url);
    return _httpRequest('GET_ALLDOCS', url);
  }

  /// Bulk insert
  /// Bulk inserts a list of documents
  Future<dynamic> bulk(List<jsonobject.JsonObjectLite<dynamic>> docs,
      // ignore: avoid_positional_boolean_parameters
      [bool allOrNothing = false]) {
    // Validate the parameters
    if (docs == null) {
      return _raiseException(WiltException.bulkNoDocList);
    }

    String url = bulkdocs;

    if (allOrNothing) {
      url = _setURLParameter(url, 'all_or_nothing', allOrNothing.toString());
    }

    // Create the bulk insertion data structure
    final Map<String, List<jsonobject.JsonObjectLite<dynamic>>> documentMap =
        <String, List<jsonobject.JsonObjectLite<dynamic>>>{};
    documentMap['docs'] = docs;
    String docString;
    try {
      docString = json.encode(documentMap);
    } on Exception {
      return _raiseException(WiltException.bulkCantStringify);
    }

    // Must set the content type for a post
    final Map<String, String> headers = <String, String>{};
    headers['Content-Type'] = 'application/json';

    url = _conditionUrl(url);
    return _httpRequest(bulkk, url, data: docString, headers: headers);
  }

  /// Bulk insert json string version.
  /// Must be used if '_id' and or '_rev' are needed in ANY of the documents
  // ignore: avoid_positional_boolean_parameters
  Future<dynamic> bulkString(String docs, [bool allOrNothing = false]) {
    // Validate the parameters
    if (docs == null) {
      return _raiseException(WiltException.bulkStringNoDoc);
    }

    String url = bulkdocs;

    if (allOrNothing) {
      url = _setURLParameter(url, 'all_or_nothing', allOrNothing.toString());
    }

    // Must set the content type for a post
    final Map<String, String> headers = <String, String>{};
    headers['Content-Type'] = 'application/json';

    url = _conditionUrl(url);
    return _httpRequest(bulkStringg, url, data: docs, headers: headers);
  }

  /// Creates a database with the specified name.
  Future<dynamic> createDatabase(String name) {
    if (name == null) {
      return _raiseException(WiltException.createDbNoName);
    }

    // The first char of the URL should be a slash.
    String url = name;
    if (!url.startsWith('/')) {
      url = '/$url';
    }

    return _httpRequest(createDatabasee, url);
  }

  /// Deletes the specified database
  Future<dynamic> deleteDatabase(String name) {
    if (name == null) {
      return _raiseException(WiltException.deleteDbNoName);
    }

    // The first char of the URL should be a slash. //
    String url = name;
    if (!url.startsWith('/')) {
      url = '/$url';
    }

    // Null the current database if we have deleted it
    if (name == db) {
      db = null;
    }

    return _httpRequest(deleteDatabasee, url);
  }

  /// Get information about a database
  Future<dynamic> getDatabaseInfo([String dbName]) {
    String name;
    if (dbName != null) {
      name = dbName;
    } else {
      name = db;
    }

    final String url = '/$name';

    return _httpRequest(databaseInfo, url);
  }

  /// Get current session information from CouchDB
  Future<dynamic> getSession() {
    const String url = session;

    return _httpRequest(getSessionn, url);
  }

  /// Get current stats from CouchDB, 1.xx versions only
  Future<dynamic> getStats() {
    const String url = stats;

    return _httpRequest(getStatss, url);
  }

  /// Get all the databases from CouchDB
  Future<dynamic> getAllDbs() {
    const String url = alldbs;

    return _httpRequest(getAllDbss, url);
  }

  /// Create an attachment on an existing document.
  /// contentType is in the form of a mime type e.g. 'image/png'
  /// If the document needs to be created as well as the attachment
  /// set the rev to ''.
  Future<dynamic> createAttachment(String docId, String attachmentName,
      String rev, String contentType, String payload) {
    // Check all parameters are supplied
    if (docId == null) {
      return _raiseException(WiltException.createAttNoDocId);
    }

    if (attachmentName == null) {
      return _raiseException(WiltException.createAttNoName);
    }

    if (rev == null) {
      return _raiseException(WiltException.createAttNoRev);
    }

    if (contentType == null) {
      return _raiseException(WiltException.createAttNoContentType);
    }

    if (payload == null) {
      return _raiseException(WiltException.createAttNoPayload);
    }

    // Set the headers
    final Map<String, String> headers = <String, String>{};
    headers['Content-Type'] = contentType;

    // Make the PUT request
    String url;
    if (rev != '') {
      url = '$docId/$attachmentName?rev=$rev';
    } else {
      url = '$docId/$attachmentName';
    }

    url = _conditionUrl(url);
    return _httpRequest(createAttachmentt, url,
        data: payload, headers: headers);
  }

  /// Update an attachment on an existing document.
  /// contentType is in the form of a mime type e.g. 'image/png'
  Future<dynamic> updateAttachment(String docId, String attachmentName,
      String rev, String contentType, String payload) {
    // Check all parameters are supplied
    if (docId == null) {
      return _raiseException(WiltException.updateAttNoDocId);
    }

    if (attachmentName == null) {
      return _raiseException(WiltException.updateAttNoName);
    }

    if (rev == null) {
      return _raiseException(WiltException.updateAttNoRev);
    }

    if (contentType == null) {
      return _raiseException(WiltException.updateAttNoContentType);
    }

    if (payload == null) {
      return _raiseException(WiltException.updateAttNoPayload);
    }

    // Set the headers
    final Map<String, String> headers = <String, String>{};
    headers['Content-Type'] = contentType;

    String url = '$docId/$attachmentName?rev=$rev';

    url = _conditionUrl(url);
    return _httpRequest(updateAttachmentt, url,
        data: payload, headers: headers);
  }

  /// Delete an attachment
  Future<dynamic> deleteAttachment(
      String docId, String attachmentName, String rev) {
    if (docId == null) {
      return _raiseException(WiltException.deleteAttNoDocId);
    }

    if (attachmentName == null) {
      return _raiseException(WiltException.deleteAttNoName);
    }

    if (rev == null) {
      return _raiseException(WiltException.deleteAttNoRev);
    }

    String url = '$docId/$attachmentName?rev=$rev';

    url = _conditionUrl(url);
    return _httpRequest(deleteAttachmentt, url);
  }

  /// Get an attachment
  Future<dynamic> getAttachment(String docId, String attachmentName) {
    if (docId == null) {
      return _raiseException(WiltException.getAttNoDocId);
    }

    if (attachmentName == null) {
      return _raiseException(WiltException.getAttNoName);
    }

    String url = '$docId/$attachmentName';

    url = _conditionUrl(url);
    return _httpRequest(getAttachmentt, url);
  }

  /// Change notification start, see the WiltChangeNotification class
  /// for more details.
  ///
  /// If a database name is not supplied the currently selected
  /// database is used.
  ///
  /// If auth credentials are not set raise an exception.
  void startChangeNotification(
      [WiltChangeNotificationParameters parameters, String databaseName]) {
    if (_user == null) {
      throw WiltException(WiltException.cnNoAuth);
    }
    String name;
    if (databaseName == null) {
      name = db;
    } else {
      name = databaseName;
    }

    changeNotificationDbName = name;
    _changeNotifier = _WiltChangeNotification(
        _host, _port, _scheme, httpAdapter, name, parameters);
  }

  /// Change notification stop, see the WiltChangeNotification
  /// class for more details
  ///
  /// Note that this destroys the internal changeNotifier object
  /// which can only be reinstated by a call to startChangeNotification.
  void stopChangeNotification() {
    _changeNotifier.stopNotifications();
    _changeNotifier = null;
    changeNotificationDbName = null;
  }

  /// Change the parameter set for change notifications.
  ///
  /// Note that database name, host, port and scheme are not changeable.
  void updateChangeNotificationParameters(
      WiltChangeNotificationParameters parameters) {
    if (parameters == null) {
      throw WiltException(WiltException.updateCnpNoParams);
    }

    if (_changeNotifier == null) {
      throw WiltException(WiltException.updateCnpNoNotifier);
    }

    _changeNotifier.parameters = parameters;
  }

  /// Pause change notifications
  void pauseChangeNotifications() {
    _changeNotifier.paused = true;
    _changeNotifier.stopNotifications();
  }

  /// Restart change notifications after a pause
  void restartChangeNotifications() {
    _changeNotifier.paused = false;
    _changeNotifier.restartChangeNotifications();
  }

  /// Authentication.
  /// Updates the login credentials in Wilt that will be used for all further
  /// requests to CouchDB. Both user name and password must be set, even if one
  /// or the other is '' i.e empty. After logging in all communication
  /// with CouchDB is made using the selected authentication method.
  void login(String user, String password) {
    if ((user == null) || (password == null)) {
      throw WiltException(WiltException.loginWrongParams);
    }

    _user = user;
    _password = password;
    authenticationType = authBasic;

    // Set the auth details for change notification
    httpAdapter.notificationAuthParams(_user, _password, authenticationType);
  }

  /// Authentication.
  /// Updates the login credentials in Wilt that will be used for all further
  /// requests to CouchDB. Both user name and password must be set, even if one
  /// or the other is '' i.e empty. After logging in all communication
  /// with CouchDB is made using the selected authentication method.
  void loginWithToken(String authToken) {
    if (authToken == null) {
      throw WiltException(WiltException.loginWrongTokens);
    }

    _token = authToken;
    authenticationType = authBearer;

    // Set the auth details for change notification
    httpAdapter.notificationAuthToken(_token, authenticationType);
  }

  /// Ask CouchDB to generate document Id's.
  Future<dynamic> generateIds([int amount = 10]) {
    if (amount < 1) {
      return _raiseException(WiltException.genIdsAmount);
    }

    String url = uuids;

    url = '$url?count=$amount';

    return _httpRequest(generateIdss, url);
  }
}
