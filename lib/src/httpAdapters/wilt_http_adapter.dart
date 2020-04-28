/*
 * Packge : Wilt
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2013
 * Copyright :  S.Hamblett@OSCF
 *
 * Provides a common interface for Wilt to connect over HTTP,
 * allowing for different HTTP adapters to be used.
 */

part of wilt;

/// HTTP adapter base class
abstract class WiltHTTPAdapter {
  /// Construction
  WiltHTTPAdapter();

  /// Processes the HTTP request returning the  HTTP response as
  /// a JSON Object
  Future<dynamic> httpRequest(String method, String url,
      [String data, Map<String, String> headers]);

  /// Specialised get for change notifications
  Future<String> getString(String url);

  /// Authentication parameters for change notification
  void notificationAuthParams(String user, String password, String authType);

  /// Authentication token parameters for change notification
  void notificationAuthToken(String token, String authType);
}
