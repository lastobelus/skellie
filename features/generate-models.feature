Feature: Generate Models

  Scenario: Basic models with attributes
    Given a file named "basic-models.yml" with:
    """
    models:
      user:
        - name:uniq
        - desc:t:ix
        - admin:bool
        - profile:jsonb
      widget:
        - name:uniq
        - category:ix
        - inventor:ref:user
    """
    When I successfully run `skellie basic-models.yml`
    Then there should be a `user` model in the app
    And the `user` schema should look like:
      | attribute | type    | index |
      | name      | string  | uniq  |
      | desc      | text    | true  |
      | admin     | boolean |       |
      | profile   | jsonb   |       |
    And there should be a `widget` model in the app
    And the `widget` schema should look like:
      | attribute   | type    | index | refs |
      | name        | string  | uniq  |      |
      | category    | string  | true  |      |
      | inventor_id | boolean |       | user |
      | profile     | jsonb   |       |      |

