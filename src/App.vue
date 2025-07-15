<template>
<div id="app">
    <navbar v-on:refresh="refreshRoute" v-if="!dashboard"></navbar>
    <transition name="fade">
        <div id="containerOverRouter" :class="containerClass">
            <router-view :key="$route.fullPath + key" class="mt-3" />
        </div>
    </transition>
    <notifications group="foo" />
    <the-footer class="footer"></the-footer>
</div>
</template>

<script>
import Navbar from "@/components/NavBar.vue";
import {
    AUTH_REQUEST,
    AUTH_CAMUNDA_REQUEST
} from "@/store/actions/auth";
import { mapState } from "vuex";

export default {
    name: "home",
    components: {
        Navbar
    },
    data() {
        return {
            containerClass: "",
            key: 1,
            dashboard: false
        };
    },
    computed: {
        ...mapState(["baseurl", "username", "password", "darktheme"]),
    },
    // watch: {
    //     baseurl(newValue) {
    //         this.$router.push({
    //             query: {
    //                 baseurl: newValue
    //             }
    //         })
    //     }
    // },

    created() {
        if (this.$route.query.baseurl) {
            this.$store.commit("setBaseUrl", this.$route.query.baseurl);
        }
    },
    mounted() {
        // // This is the core logic to fix the startup issue.
        // // It checks if the 'baseurl' parameter is missing from the current URL.
        // if (!this.$route.query.baseurl) {
        //     // If it's missing, we define the default URL for your Camunda server.
        //     const defaultUrl = 'https://camunda.eg-holding.ru/engine-rest/';
            
        //     // We then force the application to navigate to the same page ('/'),
        //     // but this time we add the '?baseurl=' parameter with your server's address.
        //     // The `catch` is there to prevent an error if we are already on the correct page.
        //     this.$router.push({ path: '/', query: { baseurl: defaultUrl } }).catch(err => {});
        // }

        if (this.$route.query.dashboard == "true") {
            this.dashboard = true;
            this.containerClass = "container width content";
        } else this.dashboard = false;

        setTimeout(() => {
            this.ContainerOrNot();
        }, 50);

        if (localStorage.usertoken != null) {
            var usertokenstring = atob(localStorage.usertoken).split(":");

            var userName = usertokenstring[0];
            var password = usertokenstring[1];
            this.$store.dispatch(AUTH_REQUEST, {
                userName,
                password
            }).then(() => {});
            this.$store
                .dispatch(AUTH_CAMUNDA_REQUEST, {
                    userName,
                    password
                })
                .then(() => {});
        }

      if (this.baseurl != null) {
        if (localStorage.restAuthArray) {
          const array = JSON.parse(localStorage.restAuthArray)
          const url = array.find(x => x.url === this.baseurl)

          if (url) {
            this.$store.commit("setRestsername", url.login);
            this.$store.commit("setRestpassword", url.password);
            this.$store.commit("setRestToken", url.JWT);
            this.$store.commit("setRestAuthType", url.type);
            this.$store.commit("setRestPasswordEnabled", true);
            this.$store.commit("setSecureDate", url.date)
          }
        }
      }
    },
    methods: {
        refreshRoute() {
            this.key = this.key + 1;
        },
        ContainerOrNot: function () {
            this.containerClass = "container content";
            if (this.dashboard == true) {
                this.containerClass = "";
            }
        }
    }
};
</script>

<style>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.5s;
}

.fade-enter,
.fade-leave-to {
    opacity: 0;
}

#containerOverRouter {
    max-width: 1400px;
    margin-top: 110px;
}

.content {
    min-height: calc(100vh - 20px);
}

.footer {
    height: 50px;
}
</style>
