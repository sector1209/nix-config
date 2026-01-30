lib: {

  mkDefaultRoles =
    roles:
    builtins.listToAttrs (
      map (role: {
        name = role;
        value = {
          enable = lib.mkDefault true;
        };
      }) roles
    );

}
