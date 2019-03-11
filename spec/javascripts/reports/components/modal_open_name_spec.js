import Vue from 'vue';
import Vuex from 'vuex';
import component from '~/reports/components/modal_open_name.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Modal open name', () => {
  const Component = (component);
  let vm;

  const store = new Vuex.Store({
    actions: {
      openModal: () => {},
    },
    state: {},
    mutations: {},
  });

  beforeEach(() => {
    vm = mountComponentWithStore(Component, {
      store,
      props: {
        issue: {
          title: 'Issue',
        },
        status: 'failed',
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the issue name', () => {
    expect(vm.$el.textContent.trim()).toEqual('Issue');
  });

  it('calls openModal actions when button is clicked', () => {
    spyOn(vm, 'openModal');

    vm.$el.click();

    expect(vm.openModal).toHaveBeenCalled();
  });
});
