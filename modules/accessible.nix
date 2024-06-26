{
  lib,
  configurationModule,
  common,
  utils,
  ...
}:
{
  options = {
    accessible = lib.mkOption {
      type = lib.types.submodule {
        options = {
          inherit (common.options) actions;
          workflows = lib.mkOption {
            type = lib.types.submodule {
              options = lib.mapAttrs (
                _: workflow:
                lib.mkOption {
                  type = lib.types.submodule {
                    options = {
                      accessors = lib.mkOption {
                        type =
                          let
                            mkAccessorOptions =
                              path:
                              lib.mapAttrs (
                                name: value:
                                let
                                  valueIsEmptyAttrs = lib.types.attrsEmpty.check value;
                                  path_ = path ++ [ name ];
                                  pathStr = lib.concatStringsSep "." path_;
                                in
                                lib.mkOption {
                                  type = lib.types.submodule' {
                                    name = "accessor";
                                    description =
                                      (if valueIsEmptyAttrs then "attribute set of (submodule)" else "empty attribute set")
                                      + " automatically convertible to string";
                                    modules = {
                                      options = (lib.optionalAttrs (!valueIsEmptyAttrs) (mkAccessorOptions path_ value)) // {
                                        __toString = lib.mkOption {
                                          type = lib.types.functionTo lib.types.str;
                                          default = _: pathStr;
                                          internal = true;
                                        };
                                      };
                                    };
                                  };
                                  default = pathStr;
                                }
                              );
                          in
                          lib.types.submodule { options = mkAccessorOptions [ ] (workflow.accessors or { }); };
                        default = { };
                      };
                      inherit (common.options) path actions on;
                      jobs = lib.mkOption {
                        type = lib.types.submodule {
                          options = lib.mapAttrs (
                            _: _:
                            lib.mkOption {
                              type = lib.types.submodule {
                                options = {
                                  inherit (common.options) name;
                                  steps = lib.mkOption {
                                    type =
                                      let
                                        step = lib.types.submodule { options = common.options.step; };
                                      in
                                      lib.types.attrsOf (
                                        lib.types.either (lib.types.functionTo (lib.types.functionTo (lib.types.listOf step))) step
                                      );
                                    default = { };
                                  };
                                };
                              };
                              default = { };
                            }
                          ) workflow.jobs;
                        };
                        default = { };
                      };
                    };
                  };
                  default = { };
                }
              ) configurationModule.config.workflows;
            };
            default = { };
          };
        };
      };
    };
  };

  config = {
    accessible = {
      inherit (configurationModule.config) actions;
      workflows = utils.resolveWorkflows {
        inherit (configurationModule) config;
        doMakeAccessors = true;
        stepsPipe = [
          (lib.foldl'
            (res: x: {
              idx = res.idx + 1;
              acc =
                res.acc
                // {
                  ${builtins.toString res.idx} = x;
                }
                // {
                  ${
                    if x ? id && x.id != null then
                      x.id
                    else if x ? alias && x.alias != null then
                      x.alias
                    else if x ? name && x.name != null then
                      x.name
                    else
                      builtins.toString res.idx
                  } = x;
                };
            })
            {
              idx = 1;
              acc = { };
            }
          )
          (x: x.acc // { __functor = self: map (x: self.${builtins.toString x}); })
        ];
      };
    };
  };
}
