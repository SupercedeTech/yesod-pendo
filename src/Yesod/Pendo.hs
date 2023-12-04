{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Yesod.Pendo where

import Data.Maybe (fromMaybe)
import Data.Text
import Yesod.Core
import Yesod.Middleware.CSP

class Yesod app => YesodPendo app where

  getApiKey :: HandlerFor app (Maybe Text)

  getUserId :: HandlerFor app (Maybe Text)

  getUserName :: HandlerFor app (Maybe Text)
  getUserName = pure Nothing

  getUserRole :: HandlerFor app (Maybe Text)
  getUserRole = pure Nothing

addPendo :: YesodPendo app => WidgetFor app ()
addPendo = do
  mApiKey <- liftHandler getApiKey
  mUserId <- liftHandler getUserId
  name    <- liftHandler getUserName
  role    <- liftHandler getUserRole

  case (mApiKey, mUserId) of

    (Nothing, _) -> pure ()

    (_, Nothing) -> pure ()

    (Just apiKey, Just userId) -> do

      addCSP ConnectSrc "app.pendo.io"
      addCSP ConnectSrc "data.pendo.io"
      addCSP ConnectSrc "pendo-static-6076670978949120.storage.googleapis.com"
      addCSP FrameSrc "app.pendo.io"
      addCSP FrameAncestors "app.pendo.io"

      toWidget [julius|
        ;(function(apiKey) {
          (function(p, e, n, d, o) {
            var v, w, x, y, z;
            o = p[d] = p[d] || {};
            o._q = o._q || [];
            v = ['initialize', 'identify', 'updateOptions', 'pageLoad', 'track'];
            for (w = 0, x = v.length; w < x; ++w)(function(m) {
              o[m] = o[m] || function() {
                o._q[m === v[0] ? 'unshift' : 'push']([m].concat([].slice.call(arguments, 0)));
              };
            })(v[w]);
            y = e.createElement(n);
            y.async = !0;
            y.src = 'https://cdn.pendo.io/agent/static/' + apiKey + '/pendo.js';
            z = e.getElementsByTagName(n)[0];
            z.parentNode.insertBefore(y, z);
          })(window, document, 'script', 'pendo');

          pendo.initialize({
            visitor: {
              id: #{userId},
              full_name: #{fromMaybe "" name},
              role: #{fromMaybe "" role}
            },
            events: {
              ready: function() {
                document.dispatchEvent(new Event("PENDO_READY"));
              },
              guidesLoaded: function() {
                document.dispatchEvent(new Event("PENDO_GUIDES_LOADED"));
              },
              guidesFailed: function() {
                document.dispatchEvent(new Event("PENDO_GUIDES_FAILED"));
              }
            }
          });
        })(#{apiKey});
      |]
