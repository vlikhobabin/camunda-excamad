# Warning 
Starting from 01.11.2024 EXCAMAD became a part of https://stormbpmn.com/ and became closed source software. We made a huge redesign, remove old dependencies, rewrite everything from vue2 to vue3, add securty and more more stuff. If you want to use excamad\stormbpmn.com on commercial base, contact us https://stormbpmn.com/contact-sales.  All previous code still covered by GNU GPLv3, but there will no more updates in open source. 


# Excamad

**Ex**ternal **cam**unda **ad**min portal. Make life in **multi-camunda`s** environment much easy and provide some cool features.
License : GNU GPLv3.

DEMO: http://excamad.bpmn2.ru (dont forget about CORS)

Description (russian): https://bpmn2.ru/blog/camunda-cockpit-enterpise-i-excamad 

# 0. How to run

a) ---make excamad---

- git clone
- npm install
- fill src/config/settings.js with own value
- npm run serve (start dev server) OR
- npm run build (produce html,js,css in to /dist/)

b) --prepare camunda--

- For stand-alone camunda: http://beninkster.com/tomcat-7-and-disabling-cors
- For embedded camunda: https://forum.camunda.org/t/camunda-cors-filter-in-spring-boot-application/5494

If you are going use docker containers add this code to camunda container in /camunda/webapps/engine-rest/WEB-INF/web.xml

" CorsFilter org.apache.catalina.filters.CorsFilter cors.allowed.origins * CorsFilter /*  "

## OR

```shell
docker run -d -p 8080:8080 kotovdenis/excamad:latest
```

# 0.1 Default camunda rest endpoint

- For embedded camunda: `${baseurl}/rest`
- For standalone camunda: `${baserurl}/engine-rest`

Excamad work with default rest api, not cockpit api. So you havent auth user in your context.

# 1. Features

## Processes

- Online statistics about active and ended processes
- Migration tool
- Batch variables editor
- Search instances in history by ID and variables
- Old activity report
- Browser viewer and modeler for deployed processes
- Jira integration (fetch issue about activities from jira)

## Decisions

- Online statistics
- Decisions viewer and modeler
- Bitbucket integration
- Deploy from browser

## Incidents

- Batch rerun activities
- Fix selected activities
- Delete failed instances

## Live

Provide facebook-like feed about activities in system.

## Tasklist

Simple forms and form generator. You need extend your Camunda rest api with method **/taskfields**

```java
//example
@Path("/")
public ctaskfieldslass TaskFieldsService {

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Path("{taskId}")
    public String getFormFieldList(
        @Context HttpHeaders httpHeaders,
        @PathParam("taskId") String taskId
    ) {
        ProcessEngine processEngine = ProcessEngines.getDefaultProcessEngine();
        FormService formService = processEngine.getFormService();
        TaskFormData taskFormData = formService.getTaskFormData(taskId);
        List<FormField> formFieldList = taskFormData.getFormFields();
        System.out.println("Strike");
        String json = JSON(formFieldList).toString();
        return json;
    }
}
```

## Business process as service

Organize camunda as provider of BPMN processes.

## Multi-camunda`s

Easy switch server and environments.

## Login

Ready login provider for basic auth and passthrough to Jira and Bitbucket.

# 2. Access to server

Excamad is serverless app - all api calls made from your browser. You need host produced files (/dist) on some web-server. And you need enable CORS on your`s camunda.

- For stand-alone camunda : http://beninkster.com/tomcat-7-and-disabling-cors
- For embedded camunda: https://forum.camunda.org/t/camunda-cors-filter-in-spring-boot-application/5494
- You can use reverse-proxy: https://www.npmjs.com/package/cors-anywhere
- You can host files on camunda host.

# 3. Install

    npm install
    -
    npm run build  // produce files in dist/
    OR
    npm run serve  // start develop server

You need write global variables in **settings.js** and **camundasUrl.js**.

## User Configuration

The application uses YAML configuration for user management. To set up users:

1. Copy `src/config/users.example.yaml` to `src/config/users.yaml`
2. Edit `users.yaml` with your actual user credentials
3. Never commit `users.yaml` to version control - it's automatically ignored

Example structure of `users.yaml`:
```yaml
system:
  camunda:
    username: "camunda_service_user"
    password: "your_strong_password_here"
    base64: "base64_encoded_credentials_here"

users:
  - username: "admin"
    password: "admin_strong_password"
```

**Important:** Always use strong passwords in production!
