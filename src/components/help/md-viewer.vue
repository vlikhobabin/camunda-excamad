<template>
  <vue-markdown :source="mdText"></vue-markdown>
</template>

<script>
import VueMarkdown from 'vue-markdown'
export default

  {
    name: 'md-viewer',
    components: {
      VueMarkdown,
    },
    props: ["src"],
    data: function () {
      return ({ "mdText": "" });
    },
    mounted() {
      // Load static files from public directory using native fetch API
      const staticFileUrl = `/${this.src}`;
      
      fetch(staticFileUrl)
        .then(response => {
          if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
          }
          return response.text();
        })
        .then(data => { 
          this.mdText = data;
        })
        .catch(error => {
          console.warn('Failed to load help file:', staticFileUrl, error);
          this.mdText = `# File not found\n\nThe help file **${this.src}** could not be loaded.\n\nPlease check if the file exists in the public/help/ directory.`;
        });
    }
  }
</script>

<style lang="scss"></style>