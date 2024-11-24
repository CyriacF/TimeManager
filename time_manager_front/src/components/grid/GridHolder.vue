<template>
  <GridLayout
      v-model:layout="layout"
      :responsive-layouts="responsiveLayouts"
      :col-num="8"
      :row-height="30"
      :is-draggable="true"
      :is-resizable="false"
      :prevent-collision="false"
      :breakpoints="{ lg: 1200, md: 1024, sm: 768, xs: 480, xxs: 0 }"
      :vertical-compact="true"
      :responsive="true"
      :use-css-transforms="true"
      :auto-size="true"
      @breakpoint-changed="breakpointChangedEvent"
  >
    <GridItem
        v-for="item in layout"
        :key="item.i"
        :i="item.i"
        :x="item.x"
        :y="item.y"
        :w="item.w"
        :h="item.h"
    >
      <Suspense>
        <template #default>
          <component :is="getComponentById(item.i)" />
        </template>
        <template #fallback>
          <div>Loading...</div>
        </template>
      </Suspense>
    </GridItem>
  </GridLayout>
</template>

<script>
import { ref, reactive } from 'vue';
import { GridLayout, GridItem } from 'grid-layout-plus';
import Clocking from './global/Clocking.vue';
import WorkingTimes from '@/components/workingTimes/WorkingTimes.vue';

export default {
  components: {
    GridLayout,
    GridItem,
    Clocking,
    WorkingTimes
  },
  setup() {
    const presetLayouts = reactive({
      lg: [
        { i: '1', x: 0, y: 0, w: 2, h: 9 }, // Premier élément occupant 4 colonnes sur les grands écrans
        { i: '2', x: 2, y: 0, w: 10, h: 9 }  // Deuxième élément occupant 8 colonnes à côté du premier
      ],
      md: [
        { i: '1', x: 0, y: 0, w: 3, h:10 }, // Les deux éléments restent côte à côte mais plus étroits
        { i: '2', x: 3, y: 0, w: 7, h: 10 }
      ],
      sm: [
        { i: '1', x: 0, y: 0, w: 8, h: 5 }, // À partir de la taille 'sm', ils prennent plus de largeur
        { i: '2', x: 0, y: 8, w: 6, h: 8 }  // Les éléments sont maintenant empilés
      ],
      xs: [
        { i: '1', x: 0, y: 0, w: 11, h: 6 }, // Sur mobile, les deux éléments sont empilés avec une largeur plus étroite
        { i: '2', x: 0, y: 8, w: 11, h: 8 }
      ]

    });

    const layout = ref(presetLayouts.lg);

    const breakpointChangedEvent = (newBreakpoint, newLayout) => {
      console.info('BREAKPOINT CHANGED:', newBreakpoint, newLayout);
      layout.value = newLayout;
    };

    return {
      layout,
      responsiveLayouts: presetLayouts,
      breakpointChangedEvent,
      getComponentById(id) {
        switch (id) {
          case '1':
            return 'Clocking';
          case '2':
            return 'WorkingTimes';
          default:
            return null;
        }
      }
    };
  }
};
</script>

<style scoped>
.vgl-layout {
  --vgl-placeholder-bg: var(--primary-color);
}

:deep(.vgl-item) {

  border: 1px solid black;
}

:deep(.vgl-item--resizing) {
  opacity: 90%;
}

.text {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  margin: auto;
  font-size: 24px;
  text-align: center;
}
</style>
