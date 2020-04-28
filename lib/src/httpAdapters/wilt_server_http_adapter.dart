/*
 * Packge : Wilt
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2013
 * Copyright :  S.Hamblett@OSCF
 *
 * Browser(dart:html) CouchDB HTTP adapter for Wilt.
 *
 * This always returns a json Object the format of which is documented in
 * the Result Interface document
 *
 */

part of wilt_server_client;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_annotating_with_dynamic

/// Server HTTP adapter
class WiltServerHTTPAdapter implements WiltHTTPAdapter {
  /// Construction
  WiltServerHTTPAdapter() {
    _client = http.Client();
  }

  /// User for change notification authorization
  String _user;

  /// Password for change notification authorization
  String _password;

  /// OAuth token for authorization. either user, password will be set or this.
  String _token;

  /// Auth Type for change notification authorization
  String _authType;

  /// HTTP client
  http.Client _client;

  /// Processes the HTTP request, returning the server's response
  /// as a future
  @override
  Future<dynamic> httpRequest(String method, String url,
      [String data, Map<String, String> headers]) {
    //  Initialise
    final Completer<dynamic> completer = Completer<dynamic>();

    /// Successful completion
    void onSuccess(http.Response response) {
      // Process the success response, note that an error response
      // from CouchDB is treated as an error, not as a success with an
      // 'error' field in it.
      final dynamic jsonResponse = jsonobject.JsonObjectLite<dynamic>();
      jsonResponse.error = false;
      jsonResponse.errorCode = response.statusCode;
      jsonResponse.successText = null;
      jsonResponse.errorText = null;
      jsonResponse.allResponseHeader = null;
      jsonResponse.method = method;
      jsonResponse.responseText = response.body;

      // Check the header, if application/json try and decode it,
      // otherwise its just raw data, ie an attachment.
      if (response.headers.containsValue('application/json')) {
        dynamic couchResp;
        try {
          couchResp = json.decode(response.body);
        } on Exception {
          jsonResponse.error = true;
          final dynamic errorAsJson = jsonobject.JsonObjectLite<dynamic>();
          errorAsJson.error = 'json Decode Error';
          errorAsJson.reason = 'None';
          jsonResponse.jsonCouchResponse = errorAsJson;
          // Set the response headers
          jsonResponse.allResponseHeaders = response.headers;

          // Complete the request
          if (!completer.isCompleted) {
            completer.complete(jsonResponse);
          }
        }

        if ((couchResp is Map) && (couchResp.containsKey('error'))) {
          jsonResponse.error = true;
          final dynamic errorAsJson = jsonobject.JsonObjectLite<dynamic>();
          errorAsJson.error = 'CouchDb Error';
          errorAsJson.reason = couchResp['reason'];
          jsonResponse.jsonCouchResponse = errorAsJson;
          // Set the response headers
          jsonResponse.allResponseHeaders = response.headers;

          // Complete the request
          if (!completer.isCompleted) {
            completer.complete(jsonResponse);
          }
        }

        // Success response
        if (method != Wilt.headd) {
          final jsonobject.JsonObjectLite<dynamic> successAsJson =
              jsonobject.JsonObjectLite<dynamic>.fromJsonString(response.body);
          jsonResponse.jsonCouchResponse = successAsJson;
        }
      } else {
        final dynamic successAsJson = jsonobject.JsonObjectLite<dynamic>();
        successAsJson.ok = true;
        successAsJson.contentType = response.headers['content-type'];
        jsonResponse.jsonCouchResponse = successAsJson;
      }

      // Set the response headers
      jsonResponse.allResponseHeaders = response.headers;

      // Complete the request
      if (!completer.isCompleted) {
        completer.complete(jsonResponse);
      }
    }

    /// Successful completion for Copy
    void onCopySuccess(http.StreamedResponse response) {
      // Process the success response, note that an error response
      // from CouchDB is treated as an error, not as a success with an
      // 'error' field in it.
      final dynamic jsonResponse = jsonobject.JsonObjectLite<dynamic>();
      jsonResponse.error = false;
      jsonResponse.errorCode = 0;
      jsonResponse.successText = null;
      jsonResponse.errorText = null;
      jsonResponse.allResponseHeader = null;
      jsonResponse.method = method;
      // ignore: avoid_types_on_closure_parameters
      response.stream.bytesToString(utf8).then((String text) {
        jsonResponse.responseText = text;

        // Check the header, if application/json try and decode it,
        // otherwise its just raw data, ie an attachment.
        if (response.headers.containsValue('application/json')) {
          dynamic couchResp;
          try {
            couchResp = json.decode(text);
          } on Exception {
            jsonResponse.error = true;
            final dynamic errorAsJson = jsonobject.JsonObjectLite<dynamic>();
            errorAsJson.error = 'json Decode Error';
            errorAsJson.reason = 'None';
            jsonResponse.jsonCouchResponse = errorAsJson;
            // Set the response headers
            jsonResponse.allResponseHeaders = response.headers;

            // Complete the request
            if (!completer.isCompleted) {
              completer.complete(jsonResponse);
            }
          }

          if ((couchResp is Map) && (couchResp.containsKey('error'))) {
            jsonResponse.error = true;
            final dynamic errorAsJson = jsonobject.JsonObjectLite<dynamic>();
            errorAsJson.error = 'CouchDb Error';
            errorAsJson.reason = couchResp['reason'];
            jsonResponse.jsonCouchResponse = errorAsJson;
            // Set the response headers
            jsonResponse.allResponseHeaders = response.headers;
            // Complete the reequest
            if (!completer.isCompleted) {
              completer.complete(jsonResponse);
            }
          }

          // Success response
          if (method != Wilt.headd) {
            final jsonobject.JsonObjectLite<dynamic> successAsJson =
                jsonobject.JsonObjectLite<dynamic>.fromJsonString(text);
            jsonResponse.jsonCouchResponse = successAsJson;
          }
        } else {
          final dynamic successAsJson = jsonobject.JsonObjectLite<dynamic>();
          successAsJson.ok = true;
          successAsJson.contentType = response.headers['content-type'];
          jsonResponse.jsonCouchResponse = successAsJson;
        }

        // Set the response headers
        jsonResponse.allResponseHeaders = response.headers;

        // Complete the request
        if (!completer.isCompleted) {
          completer.complete(jsonResponse);
        }
      });
    }

    /// Error completion
    void onError(dynamic exception) {
      // Process the error response
      final dynamic jsonResponse = jsonobject.JsonObjectLite<dynamic>();
      jsonResponse.method = method;
      jsonResponse.error = true;
      jsonResponse.successText = null;
      jsonResponse.errorCode = 0;
      final dynamic errorAsJson = jsonobject.JsonObjectLite<dynamic>();
      errorAsJson.error = 'Invalid HTTP response';
      errorAsJson.reason = exception.message;
      jsonResponse.jsonCouchResponse = errorAsJson;

      // Complete the request
      if (!completer.isCompleted) {
        completer.complete(jsonResponse);
      }
    }

    // Condition the input method string to get the HTTP method
    final String httpMethod = method.split('_')[0];

    // Set the content type header correctly
    if (headers.containsKey('Content-Type')) {
      final String contentType = headers['Content-Type'];
      headers.remove('Content-Type');
      headers['content-type'] = contentType;
    }

    // Query CouchDB over HTTP
    if (httpMethod == 'GET') {
      _client.get(url, headers: headers).then(onSuccess, onError: onError);
    } else if (httpMethod == 'PUT') {
      _client
          .put(url, headers: headers, body: data)
          .then(onSuccess, onError: onError);
    } else if (httpMethod == 'POST') {
      _client
          .post(url, headers: headers, body: data)
          .then(onSuccess, onError: onError);
    } else if (httpMethod == 'HEAD') {
      _client.head(url, headers: headers).then(onSuccess, onError: onError);
    } else if (httpMethod == 'DELETE') {
      _client.delete(url, headers: headers).then(onSuccess, onError: onError);
    } else if (httpMethod == 'COPY') {
      final Uri encodedUrl = Uri.parse(url);
      final dynamic request = http.Request('COPY', encodedUrl);
      request.headers.addAll(headers);
      _client.send(request).then(onCopySuccess, onError: onError);
    }

    return completer.future;
  }

  /// Specialised 'get' for change notifications
  @override
  Future<String> getString(String url) {
    final Completer<dynamic> completer = Completer<String>();

    // Must have authentication
    final Map<String, String> wiltHeaders = <String, String>{};
    wiltHeaders['Accept'] = 'application/json';
    if (_user != null) {
      switch (_authType) {
        case Wilt.authBasic:
          final String authStringToEncode = '$_user:$_password';
          final String encodedAuthString =
              const Base64Encoder().convert(authStringToEncode.codeUnits);
          final String authString = 'Basic $encodedAuthString';
          wiltHeaders['Authorization'] = authString;
          break;

        case Wilt.authBearer:
          wiltHeaders['authorization'] = 'Bearer $_token';
          break;

        case Wilt.authNone:
          break;
      }
    }

    _client.get(url, headers: wiltHeaders).then((dynamic response) {
      completer.complete(response.body);
    });

    return completer.future;
  }

  /// Authentication parameters for change notification
  @override
  void notificationAuthParams(String user, String password, String authType) {
    _user = user;
    _password = password;
    _authType = authType;
  }

  /// Authentication token parameters
  @override
  void notificationAuthToken(String token, String authType) {
    _token = token;
    _authType = authType;
  }
}
