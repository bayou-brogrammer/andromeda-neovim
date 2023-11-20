{lib, ...}: {
  genAttrs' = values: f: with lib; listToAttrs (map (v: nameValuePair (f v) v) values);
}
