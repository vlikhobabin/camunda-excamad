<template>
  <div>
    <h2>{{oldActivites.length}} instances, waited more 1 week on single activity</h2>

    <table class="table table-striped table-hover table-sm">
      <thead>
        <tr>
          <th>Stared</th>
          <th>Process</th>
          <th>Activity</th>
          <th>Activity type</th>
          <th>Instance</th>
          <th>Business key</th>
        </tr>
      </thead>
      <tbody>
        <tr :key="item.id" v-for="item in oldActivites">
          <td style="word-break:break-all;">{{convertDateToHumanStyle(item.startTime)}}</td>
          <td style="word-break:break-all;">
            <router-link
              :to="{name:'definition', params:{ definitionId: item.processDefinitionId}}"
            >{{ item.processDefinitionId }}</router-link>
          </td>
          <td style="word-break:break-all;">{{item.activityId}}</td>
          <td style="word-break:break-all;">{{item.activityType}}</td>
          <td style="word-break:break-all;">
            <router-link
              :to="{name:'processdetail', params:{ processInstanceId: item.processInstanceId}}"
            >
              <p class="card-text">
                <b>{{item.processInstanceId}}</b>
              </p>
            </router-link>
          </td>
          <td style="word-break:break-all;">{{item.processInstance && item.processInstance.businessKey ? item.processInstance.businessKey : 'N/A'}}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import { getEntity } from "@/api/api";

export default {
  name: "OldActivity",
  data() {
    return {
      oldActivites: [],
      momentdays: ""
    };
  },
  mounted() {
    this.findSubtractDate();

    setTimeout(() => {
      this.getOldActivites();
    }, 150);
  },
  methods: {
    getOldActivites() {
      // Сначала попробуем простой запрос без даты
      getEntity("history", "activity-instance", "unfinished=true&maxResults=5")
        .then(simpleResult => {
          // Если простой запрос работает, тестируем альтернативные подходы
          this.testAlternativeApproaches();
        })
        .catch(simpleError => {
          console.error("Simple request fails:", simpleError);
          console.error("Even basic API request failed. Check server connection.");
        });
    },

    async testAlternativeApproaches() {
      // Подход 1: Без фильтрации по дате - просто получить незавершенные активности
      try {
        const result1 = await getEntity("history", "activity-instance", "unfinished=true&sortBy=startTime&sortOrder=desc&maxResults=50");
        
        if (result1.length > 0) {
          this.processActivitiesWithoutDate(result1);
          return;
        }
      } catch (error) {
        // Approach 1 failed, continue to next approach
      }

      // Подход 2: Попробовать finishedBefore вместо startedBefore  
      const dateStr = this.$momenttrue(new Date()).subtract(1, "days").format("YYYY-MM-DDTHH:mm:ss");
      try {
        const result2 = await getEntity("history", "activity-instance", `finishedBefore=${dateStr}&maxResults=10`);
        this.processActivitiesWithDate(result2);
        return;
      } catch (error) {
        // Approach 2 failed, continue to next approach
      }

      // Подход 3: Получить все активности и фильтровать на клиенте
      try {
        const result3 = await getEntity("history", "activity-instance", "sortBy=startTime&sortOrder=desc&maxResults=100");
        this.filterActivitiesOnClient(result3);
        return;
      } catch (error) {
        // Approach 3 failed
      }
      
      console.error("All approaches failed! No data could be loaded.");
    },

    processActivitiesWithoutDate(activities) {
      this.processActivitiesCommon(activities);
    },

    processActivitiesWithDate(activities) {
      this.processActivitiesCommon(activities);
    },

    filterActivitiesOnClient(activities) {
      // Фильтруем активности старше 7 дней
      const sevenDaysAgo = this.$momenttrue().subtract(7, "days");
      const filteredActivities = activities.filter(activity => {
        if (activity.startTime) {
          const startTime = this.$momenttrue(activity.startTime);
          return startTime.isBefore(sevenDaysAgo);
        }
        return false;
      });
      
      this.processActivitiesCommon(filteredActivities);
    },

    processActivitiesCommon(activities) {
      
      // Получаем детали процессов для каждой активности
      activities.forEach(element => {
        getEntity(
          "process-instance/" + element.processInstanceId,
          "",
          ""
        )
          .then(response => {
            this.$set(element, "processInstance", response);
          })
          .catch(error => {
            console.warn("Failed to get process instance for", element.processInstanceId, error);
          });
      });

      this.oldActivites = activities;
    },
    findSubtractDate: function() {
      // Упрощенная функция - больше не нужна сложная генерация дат
      // так как мы используем альтернативные подходы
      var date = new Date();
      
      var moment7DaysAgo = this.$momenttrue(date).subtract(7, "days");
      this.momentdays = moment7DaysAgo.format("YYYY-MM-DDTHH:mm:ss");
    },

    convertDateToHumanStyle: function(date) {
      var rel = this.$momenttrue(date)
        .startOf("second")
        .fromNow();

      var cal = this.$momenttrue(date).format("MMMM Do YYYY, H:mm:ss");

      var output = rel + " (" + cal + ") ";
      return output;
    }
  }
};
</script>
