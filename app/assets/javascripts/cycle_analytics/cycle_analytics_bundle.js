import $ from 'jquery';
import Vue from 'vue';
import Cookies from 'js-cookie';
import Flash from '../flash';
import Translate from '../vue_shared/translate';
import banner from './components/banner.vue';
// TODO: should the be capitalized?
import addStageForm from './components/add_stage_form.vue';
import stageCodeComponent from './components/stage_code_component.vue';
import stageComponent from './components/stage_component.vue';
import stageReviewComponent from './components/stage_review_component.vue';
import stageStagingComponent from './components/stage_staging_component.vue';
import stageTestComponent from './components/stage_test_component.vue';
import customStageForm from './components/custom_stage_form.vue';
import CycleAnalyticsService from './cycle_analytics_service';
import CycleAnalyticsStore from './cycle_analytics_store';
import { __ } from '~/locale';

Vue.use(Translate);

export default () => {
  const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';
  const cycleAnalyticsEl = document.querySelector('#cycle-analytics');

  // eslint-disable-next-line no-new
  new Vue({
    el: '#cycle-analytics',
    name: 'CycleAnalytics',
    components: {
      banner,
      addStageForm,
      'stage-issue-component': stageComponent,
      'stage-plan-component': stageComponent,
      'stage-code-component': stageCodeComponent,
      'stage-test-component': stageTestComponent,
      'stage-review-component': stageReviewComponent,
      'stage-staging-component': stageStagingComponent,
      'stage-production-component': stageComponent,
      'custom-stage-form': customStageForm,
    },
    data() {
      const cycleAnalyticsService = new CycleAnalyticsService({
        requestPath: cycleAnalyticsEl.dataset.requestPath,
      });

      return {
        store: CycleAnalyticsStore,
        state: CycleAnalyticsStore.state,
        isLoading: false,
        isLoadingStage: false,
        isEmptyStage: false,
        hasError: false,
        startDate: 30,
        isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
        service: cycleAnalyticsService,
        isCustomStageForm: false,
      };
    },
    computed: {
      currentStage() {
        return this.store.currentActiveStage();
      },
    },
    created() {
      // Conditional check placed here to prevent this method from being called on the
      // new Cycle Analytics page (i.e. the new page will be initialized blank and only
      // after a group is selected the cycle analyitcs data will be fetched). Once the
      // old (current) page has been removed this entire created method as well as the
      // variable itself can be completely removed.
      // Follow up issue: https://gitlab.com/gitlab-org/gitlab-ce/issues/64490
      if (cycleAnalyticsEl.dataset.requestPath) this.fetchCycleAnalyticsData();
      // TODO: remove
      this.addStageForm = true;
    },
    methods: {
      handleError() {
        this.store.setErrorState(true);
        return new Flash(__('There was an error while fetching cycle analytics data.'));
      },
      initDropdown() {
        const $dropdown = $('.js-ca-dropdown');
        const $label = $dropdown.find('.dropdown-label');

        $dropdown
          .find('li a')
          .off('click')
          .on('click', e => {
            e.preventDefault();
            const $target = $(e.currentTarget);
            this.startDate = $target.data('value');

            $label.text($target.text().trim());
            this.fetchCycleAnalyticsData({ startDate: this.startDate });
          });
      },
      fetchCycleAnalyticsData(options) {
        const fetchOptions = options || { startDate: this.startDate };

        this.isLoading = true;

        this.service
          .fetchCycleAnalyticsData(fetchOptions)
          .then(response => {
            this.store.setCycleAnalyticsData(response);
            this.selectDefaultStage();
            this.initDropdown();
            this.isLoading = false;
          })
          .catch(() => {
            this.handleError();
            this.isLoading = false;
          });
      },
      selectDefaultStage() {
        const stage = this.state.stages[0];
        this.selectStage(stage);
      },
      selectStage(stage) {
        if (this.isLoadingStage) return;
        if (this.currentStage === stage) return;

        if (!stage.isUserAllowed) {
          this.store.setActiveStage(stage);
          return;
        }

        this.isLoadingStage = true;
        this.store.setStageEvents([], stage);
        this.store.setActiveStage(stage);

        this.service
          .fetchStageData({
            stage,
            startDate: this.startDate,
          })
          .then(response => {
            this.isEmptyStage = !response.events.length;
            this.store.setStageEvents(response.events, stage);
            this.isLoadingStage = false;
          })
          .catch(() => {
            this.isEmptyStage = true;
            this.isLoadingStage = false;
          });
      },
      showAddStageForm() {
        console.log('cycle_analytics_bundle::showAddStageForm', this);
        // TODO: should these eventually be moved to actions for a vuex store
        this.isLoadingStage = true;

        // TODO: do async-y stuff if we need it?
        // Maybe loading the data, but most likely we can bootstrap that in the form as props

        // TODO: perhaps could be something more like this.activeStage('stage-name') ie loading, empty, custom form etc

        // Should eventually be actions emitted to the vuex store
        this.isCustomStageForm = true;
        this.isLoadingStage = false;
      },
      dismissOverviewDialog() {
        this.isOverviewDialogDismissed = true;
        Cookies.set(OVERVIEW_DIALOG_COOKIE, '1', { expires: 365 });
      },
    },
  });
};
