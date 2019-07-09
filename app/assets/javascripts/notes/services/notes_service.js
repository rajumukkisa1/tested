import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default {
  fetchDiscussions(endpoint, filter) {
    const config = filter !== undefined ? { params: { notes_filter: filter } } : null;
    return Vue.http.get(endpoint, config);
  },
  deleteNote(endpoint) {
    return Vue.http.delete(endpoint);
  },
  replyToDiscussion(endpoint, data) {
    return Vue.http.post(endpoint, data, { emulateJSON: true });
  },
  updateNote(endpoint, data) {
    return Vue.http.put(endpoint, data, { emulateJSON: true });
  },
  createNewNote(endpoint, data) {
    return Vue.http.post(endpoint, data, { emulateJSON: true });
  },
  poll(data = {}) {
    const endpoint = data.notesData.notesPath;
    const { lastFetchedAt } = data;
    const options = {
      headers: {
        'X-Last-Fetched-At': lastFetchedAt ? `${lastFetchedAt}` : undefined,
      },
    };

    return Vue.http.get(endpoint, options);
  },
  toggleAward(endpoint, data) {
    return Vue.http.post(endpoint, data, { emulateJSON: true });
  },
  toggleIssueState(endpoint, data) {
    return Vue.http.put(endpoint, data);
  },
};
