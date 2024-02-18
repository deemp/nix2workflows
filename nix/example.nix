{ workflows
, actions
, qq
, null_
, stepsIf
, ...
}:
{
  actions = {
    checkout = {
      name = "actions/checkout@v4";
      with_ = {
        repository = "abra";
        filter = "filter";
      };
    };
  };

  workflows = {
    workflow-1 = {
      path = ".github/workflows/action.yaml";
      actions = { };
      jobs = {
        a = {
          name = "Hello";
          steps = [
            {
              id = "1";
              uses.checkout = {
                with_ = {
                  filter = "filter-1";
                  a = null_;
                };
              };
            }
            {
              uses = "actions/cache";
              alias = "cache";
            }
            (
              stepsIf false [
                {
                  uses = "actions/cache";
                  alias = "cache";
                }
              ]
            )
          ];
        };

        b = {
          name = qq workflows.workflow-1.jobs.a.name + qq workflows.workflow-1.jobs.a.name;
          steps = [
            {
              name = "hello";
              uses.checkout = {
                with_ = {
                  repository = "abra";
                  filter = null_;
                };
              };
            }
            [
              {
                uses = workflows.workflow-1.jobs.a.steps."2".uses;
              }
              {
                uses = workflows.workflow-1.jobs.a.steps.cache.uses;
              }
            ]
          ]
          ++
          (workflows.workflow-1.jobs.a.steps [ "cache" ])
          ;
        };
      };
    };

    workflow-2 = {
      path = ".github/workflows/action-2.yaml";

      jobs = {
        a = {
          name = workflows.workflow-1.jobs.b.name;
          steps = [
            {
              id = "1";
            }
          ];
        };
      };
    };
  };
}
