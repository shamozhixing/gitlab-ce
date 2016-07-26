((global) => {
  class Dispatcher {
    constructor() {
      this.actions = [];
      this.domLoaded = false;
      $(this.onDomLoad);
    }

    onDomLoad() {
      this.domLoaded = true;
      execute();
    }

    execute() {
      let currentPage = $('body').attr('data-page');
      for (action of this.actions) {
        if (currentPage.startsWith(action.pageQuery)) {
          action();
        }
      }
    }

    static register(pageQueries, action) {
      if (typeof pageQueries === 'array') {
        for (pageQuery of pageQueries) {
          this.actions.push({
            pageQuery,
            action
          })
        }
      } else {
        this.actions.push({
          pageQuery,
          action
        });
      }
      if (this.domLoaded) this.execute();
    }
  }

  global.Dispatcher = Dispatcher;
})(window);
